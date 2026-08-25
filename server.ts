import "dotenv/config";
import express, { type Request, type Response } from "express";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { randomBytes, scryptSync, timingSafeEqual } from "node:crypto";
import { Pool, type PoolClient, types } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { SignJWT, jwtVerify } from "jose";
import { parse, serialize } from "cookie";
import { initTRPC, TRPCError } from "@trpc/server";
import { createExpressMiddleware } from "@trpc/server/adapters/express";
import { z } from "zod";

const TAX_RATE = 0.075;
const ACTIVE_STATUSES = ["pending", "confirmed", "checked_in"] as const;
// Postgres `date` columns (check_in/check_out) are parsed into JS Date objects
// by pg's default type parser (OID 1082). Once those cross the tRPC boundary as
// JSON they become full ISO timestamps ("2026-01-15T00:00:00.000Z"), but every
// consumer in this app — client-side `shortDate`, the arrivals KPI comparison,
// room-search date matching, the CSV export, monthly analytics grouping — treats
// check-in/check-out as plain "YYYY-MM-DD" strings. Returning the raw column
// text instead of a parsed Date keeps that contract true everywhere at once,
// rather than converting back to a string at each call site individually.
types.setTypeParser(types.builtins.DATE, value => value);
const PORT = Number(process.env.PORT || 3000);
const ROOT = path.dirname(fileURLToPath(import.meta.url));
// In production this file runs as dist/server.js, so ROOT is dist/ and the built
// client lives right next to it at dist/public. In dev it runs as server.ts from
// the project root via tsx, so ROOT is the project root and the built client
// (from `npm run build:client`) lives at dist/public relative to that root.
// Resolving on path.basename(ROOT) keeps both cases pointed at the same build
// output instead of dev looking for a "public" folder that never gets created.
const PUBLIC_DIR = path.basename(ROOT) === "dist" ? path.join(ROOT, "public") : path.join(ROOT, "dist", "public");
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: Number(process.env.DB_POOL_MAX || 10),
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 10_000,
  ssl: process.env.DATABASE_URL && !/localhost|127\.0\.0\.1|::1/i.test(process.env.DATABASE_URL) ? { rejectUnauthorized: false } : undefined,
});
const db = drizzle(pool);

type Row = Record<string, any>;
type Staff = { id: number; username: string; displayName: string; staffRole: string };

function requireDatabase() {
  if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL is not configured.");
  if (!/^postgres(?:ql)?:\/\//i.test(process.env.DATABASE_URL)) throw new Error("DATABASE_URL must be a PostgreSQL connection string.");
}
async function sql<T extends Row = Row>(text: string, values: unknown[] = [], client: PoolClient | Pool = pool) {
  requireDatabase();
  return (await client.query<T>(text, values)).rows;
}
async function verifyDatabaseConnection() { requireDatabase(); await db.execute("select 1"); }

function passwordRecord(password: string) {
  const salt = randomBytes(16).toString("base64url");
  return { passwordSalt: salt, passwordHash: scryptSync(password, salt, 64).toString("base64url") };
}
function passwordMatches(password: string, salt: string, hash: string) {
  const actual = Buffer.from(scryptSync(password, salt, 64).toString("base64url"));
  const expected = Buffer.from(hash);
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
function jwtKey() { return new TextEncoder().encode(process.env.JWT_SECRET || "development-only-bnakowa-key"); }
function credentials() {
  const username = (process.env.BNAKOWA_ADMIN_USERNAME || "admin").trim().toLowerCase();
  const password = process.env.BNAKOWA_ADMIN_PASSWORD || (process.env.NODE_ENV === "production" ? (() => { throw new Error("BNAKOWA_ADMIN_PASSWORD is required in production."); })() : "BnakowaAdmin!2026");
  return { username, password };
}
async function ensureSeedAdmin() {
  const { username, password } = credentials();
  const found = await sql("select id, username, display_name as \"displayName\", staff_role as \"staffRole\", is_active as \"isActive\" from staff_accounts where username=$1 limit 1", [username]);
  if (found[0]) return found[0] as Staff;
  const record = passwordRecord(password);
  const created = await sql("insert into staff_accounts (username,password_hash,password_salt,display_name,staff_role,is_active) values ($1,$2,$3,$4,'owner',true) returning id, username, display_name as \"displayName\", staff_role as \"staffRole\"", [username, record.passwordHash, record.passwordSalt, "B-NAKOWA Administrator"]);
  return created[0] as Staff;
}
async function ensureDatabaseReady() {
  const schemaState = await sql("select to_regclass('public.properties') as table_name");
  if (!schemaState[0]?.table_name) throw new Error("Database schema is missing. Run 001_schema.sql in the Neon SQL Editor first.");
  const property = await sql("select id from properties where slug='b-nakowa' limit 1");
  if (!property[0]) throw new Error("B-NAKOWA seed data is missing. Run 002_seed.sql in the Neon SQL Editor after the schema script.");
  await ensureSeedAdmin();
}

function sessionCookie(token: string) { return serialize("bnakowa_staff_session", token, { httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax", path: "/", maxAge: 8 * 60 * 60 }); }
function readStaff(req: Request): Promise<Staff | undefined> | Staff | undefined {
  const token = parse(req.headers.cookie || "").bnakowa_staff_session || req.headers["x-bnakowa-session"]?.toString() || (req.headers.authorization?.startsWith("Bearer ") ? req.headers.authorization.slice(7) : undefined);
  if (!token) return undefined;
  return jwtVerify(token, jwtKey()).then(({ payload }) => {
    if (!payload.sub || typeof payload.username !== "string" || typeof payload.displayName !== "string" || typeof payload.staffRole !== "string") return undefined;
    return { id: Number(payload.sub), username: payload.username, displayName: payload.displayName, staffRole: payload.staffRole };
  }).catch(() => undefined);
}
function nights(checkIn: string, checkOut: string) { return Math.max(1, Math.round((Date.parse(`${checkOut}T00:00:00Z`) - Date.parse(`${checkIn}T00:00:00Z`)) / 86_400_000)); }
function validStay(checkIn: string, checkOut: string) { return Boolean(checkIn && checkOut && Date.parse(checkIn) < Date.parse(checkOut)); }
function overlap(a: string, b: string, c: string, d: string) { return c < b && d > a; }
function matchScore(input: any, room: any) {
  let score = 56; const reasons: string[] = [];
  if (room.maxOccupancy >= input.guests && room.maxOccupancy <= input.guests + 1) { score += 14; reasons.push("comfortably sized for your party"); }
  if (input.budget) input.budget >= room.baseRate ? (score += 14, reasons.push("within your preferred nightly budget")) : score -= Math.min(18, Math.ceil(((room.baseRate - input.budget) / input.budget) * 18));
  if (input.view && room.viewLabel.toLowerCase().includes(input.view.toLowerCase())) { score += 10; reasons.push("aligned with your view preference"); }
  if (input.amenity && room.amenityNames.join(" ").toLowerCase().includes(input.amenity.toLowerCase())) { score += 10; reasons.push("includes your preferred amenity"); }
  if (room.availableRooms > 1) score += 3;
  return { score: Math.max(40, Math.min(99, score)), reasons: reasons.length ? reasons : ["a strong overall match for this stay"] };
}
async function property() { const rows = await sql("select * from properties where slug='b-nakowa' limit 1"); if (!rows[0]) throw new Error("B-NAKOWA property is not initialized."); return rows[0]; }
async function searchRooms(input: any) {
  if (!validStay(input.checkIn, input.checkOut)) throw new Error("Choose a valid check-in and check-out date");
  const p = await property();
  const types = await sql("select * from room_types where property_id=$1 and is_active=true order by base_rate", [p.id]);
  const rooms = await sql("select * from rooms where property_id=$1 and status='available'", [p.id]);
  const bookings = await sql("select rr.room_id as \"roomId\", r.check_in as \"checkIn\", r.check_out as \"checkOut\" from reservation_rooms rr join reservations r on r.id=rr.reservation_id where r.property_id=$1 and r.status = any($2::reservation_status[])", [p.id, ACTIVE_STATUSES]);
  const amenityRows = await sql("select rta.room_type_id as \"roomTypeId\", a.name, a.icon from room_type_amenities rta join amenities a on a.id=rta.amenity_id");
  return types.map(type => {
    const blocked = new Set(bookings.filter(b => overlap(input.checkIn, input.checkOut, b.checkIn, b.checkOut)).map(b => Number(b.roomId)));
    const availableRooms = rooms.filter(r => Number(r.room_type_id) === Number(type.id) && !blocked.has(Number(r.id))).length;
    const amenities = amenityRows.filter(a => Number(a.roomTypeId) === Number(type.id));
    const score = matchScore(input, { baseRate: Number(type.base_rate), maxOccupancy: type.max_occupancy, viewLabel: type.view_label, amenityNames: amenities.map(a => a.name), availableRooms });
    return { id: Number(type.id), name: type.name, description: type.description, baseRate: Number(type.base_rate), maxOccupancy: type.max_occupancy, bedConfiguration: type.bed_configuration, sizeSqm: Number(type.size_sqm), viewLabel: type.view_label, accent: type.accent, availableRooms, amenities, matchScore: score.score, reasons: score.reasons };
  }).filter(r => r.availableRooms > 0 && r.maxOccupancy >= input.guests).sort((a, b) => b.matchScore - a.matchScore || a.baseRate - b.baseRate);
}
async function createReservation(input: any) {
  if (!validStay(input.checkIn, input.checkOut)) throw new Error("Choose a valid stay");
  const p = await property(); const client = await pool.connect();
  try {
    await client.query("begin");
    const type = (await sql("select * from room_types where id=$1 and property_id=$2 and is_active=true limit 1", [input.roomTypeId, p.id], client))[0];
    if (!type || type.max_occupancy < input.adults + input.children) throw new Error("This room type is not suitable for the party size");
    const candidates = await sql("select * from rooms where property_id=$1 and room_type_id=$2 and status='available' order by room_number for update", [p.id, input.roomTypeId], client);
    let room: Row | undefined;
    for (const candidate of candidates) {
      const conflicts = await sql("select r.check_in as \"checkIn\", r.check_out as \"checkOut\" from reservation_rooms rr join reservations r on r.id=rr.reservation_id where rr.room_id=$1 and r.status = any($2::reservation_status[])", [candidate.id, ACTIVE_STATUSES], client);
      if (!conflicts.some(c => overlap(input.checkIn, input.checkOut, c.checkIn, c.checkOut))) { room = candidate; break; }
    }
    if (!room) throw new Error("That room was just booked. Please choose another recommendation.");
    const email = input.email.trim().toLowerCase();
    const existing = (await sql("select id from guests where email=$1 limit 1", [email], client))[0];
    const guestId = existing?.id || (await sql("insert into guests (first_name,last_name,email,phone,marketing_opt_in) values ($1,$2,$3,$4,$5) returning id", [input.firstName.trim(), input.lastName.trim(), email, input.phone?.trim() || null, Boolean(input.marketingOptIn)], client))[0].id;
    if (existing) await sql("update guests set first_name=$1,last_name=$2,phone=$3,marketing_opt_in=$4 where id=$5", [input.firstName.trim(), input.lastName.trim(), input.phone?.trim() || null, Boolean(input.marketingOptIn), guestId], client);
    const reservationCode = `BNK-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
    const totalNights = nights(input.checkIn, input.checkOut); const subtotal = Number(type.base_rate) * totalNights; const tax = subtotal * TAX_RATE; const total = subtotal + tax;
    const reservation = (await sql("insert into reservations (reservation_code,property_id,guest_id,check_in,check_out,adults,children,source,status,subtotal,tax_amount,total_amount,special_requests) values ($1,$2,$3,$4,$5,$6,$7,'direct','confirmed',$8,$9,$10,$11) returning id", [reservationCode, p.id, guestId, input.checkIn, input.checkOut, input.adults, input.children, subtotal.toFixed(2), tax.toFixed(2), total.toFixed(2), input.specialRequests?.trim() || null], client))[0];
    await sql("insert into reservation_rooms (reservation_id,room_id,nightly_rate) values ($1,$2,$3)", [reservation.id, room.id, Number(type.base_rate).toFixed(2)], client);
    await sql("insert into payments (reservation_id,amount,method,status,transaction_ref,paid_at) values ($1,$2,'card','authorized',$3,now())", [reservation.id, total.toFixed(2), `booking_${reservationCode.toLowerCase()}`], client);
    await sql("insert into audit_events (action,entity_type,entity_id,metadata) values ('reservation.created','reservation',$1,$2)", [reservation.id, JSON.stringify({ source: "public_booking", roomId: room.id, roomTypeId: type.id })], client);
    await client.query("commit");
    return { code: reservationCode, reservationId: Number(reservation.id), totalAmount: total, currency: p.currency, roomName: type.name, roomNumber: room.room_number, nights: totalNights };
  } catch (error) { await client.query("rollback"); throw error; } finally { client.release(); }
}
async function dashboard() {
  const p = await property();
  const reservations = await sql("select r.*, g.first_name as guest_first_name,g.last_name as guest_last_name,g.email as guest_email,g.phone as guest_phone,g.loyalty_tier as guest_loyalty_tier,g.marketing_opt_in as guest_marketing_opt_in, rr.room_id, rm.room_number, rt.name as room_type_name from reservations r join guests g on g.id=r.guest_id left join reservation_rooms rr on rr.reservation_id=r.id left join rooms rm on rm.id=rr.room_id left join room_types rt on rt.id=rm.room_type_id where r.property_id=$1 order by r.created_at desc", [p.id]);
  const rooms = await sql("select * from rooms where property_id=$1 order by room_number", [p.id]);
  const roomTypes = await sql("select * from room_types where property_id=$1 order by id", [p.id]);
  const guests = await sql("select * from guests order by created_at desc");
  const tasks = await sql("select * from housekeeping_tasks where property_id=$1 order by due_at nulls last", [p.id]);
  const formatted = reservations.map(r => ({ ...r, id: Number(r.id), reservationCode: r.reservation_code, checkIn: r.check_in, checkOut: r.check_out, totalAmount: r.total_amount, guestId: Number(r.guest_id), adults: r.adults, status: r.status, guest: { firstName: r.guest_first_name, lastName: r.guest_last_name, email: r.guest_email }, assignment: r.room_id ? { roomNumber: r.room_number, roomTypeName: r.room_type_name } : undefined }));
  const revenue = formatted.filter(r => !["cancelled", "no_show"].includes(r.status)).reduce((sum, r) => sum + Number(r.totalAmount), 0);
  return { property: p, kpis: { arrivals: formatted.filter(r => ACTIVE_STATUSES.includes(r.status) && r.checkIn >= new Date().toISOString().slice(0, 10)).length, inHouse: formatted.filter(r => r.status === "checked_in").length, revenue, roomsAvailable: rooms.filter(r => r.status === "available").length }, arrivals: formatted.slice(0, 5), openTasks: tasks.filter(t => t.status !== "completed").length, reservations: formatted, roomTypes: roomTypes.map(r => ({ ...r, id: Number(r.id), name: r.name, baseRate: Number(r.base_rate), bedConfiguration: r.bed_configuration, sizeSqm: Number(r.size_sqm), viewLabel: r.view_label, maxOccupancy: r.max_occupancy, accent: r.accent })), rooms: rooms.map(r => ({ ...r, id: Number(r.id), roomTypeId: Number(r.room_type_id), roomNumber: r.room_number })), tasks: tasks.map(t => ({ ...t, id: Number(t.id), roomId: Number(t.room_id), taskType: t.task_type })), guests: guests.map(g => ({ ...g, id: Number(g.id), firstName: g.first_name, lastName: g.last_name, marketingOptIn: g.marketing_opt_in, loyaltyTier: g.loyalty_tier })) };
}
async function analytics() { const rows = await sql("select check_in,total_amount,status from reservations where property_id=(select id from properties where slug='b-nakowa') order by check_in"); const byMonth = new Map<string, { bookings: number; revenue: number }>(); for (const r of rows) { const month = String(r.check_in).slice(0, 7); const item = byMonth.get(month) || { bookings: 0, revenue: 0 }; item.bookings++; if (!["cancelled", "no_show"].includes(r.status)) item.revenue += Number(r.total_amount); byMonth.set(month, item); } return Array.from(byMonth, ([month, v]) => ({ month, label: month, bookings: v.bookings, revenue: Number(v.revenue.toFixed(2)) })); }
function csv(value: unknown) { const text = value == null ? "" : String(value); return /[",\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text; }
async function reservationCsv() { const rows = await sql("select r.reservation_code,g.first_name,g.last_name,g.email,g.phone,r.check_in,r.check_out,r.adults,r.children,r.source,r.status,r.total_amount,rm.room_number,rt.name as room_type_name from reservations r join guests g on g.id=r.guest_id left join reservation_rooms rr on rr.reservation_id=r.id left join rooms rm on rm.id=rr.room_id left join room_types rt on rt.id=rm.room_type_id where r.property_id=(select id from properties where slug='b-nakowa') order by r.created_at desc"); const header = "Reservation Code,Guest Name,Email,Phone,Check-in,Check-out,Adults,Children,Source,Status,Total Amount,Room,Room Type"; return [header, ...rows.map(r => [r.reservation_code, `${r.first_name} ${r.last_name}`, r.email, r.phone, r.check_in, r.check_out, r.adults, r.children, r.source, r.status, r.total_amount, r.room_number, r.room_type_name].map(csv).join(","))].join("\n"); }

const t = initTRPC.context<{ req: Request; res: Response; staff?: Staff }>().create();
const publicProcedure = t.procedure;
const staffProcedure = publicProcedure.use(({ ctx, next }) => ctx.staff ? next({ ctx }) : Promise.reject(new TRPCError({ code: "UNAUTHORIZED", message: "Sign in with local B-NAKOWA staff credentials." })));
const inputSearch = z.object({ checkIn: z.string(), checkOut: z.string(), guests: z.number().int().min(1).max(8), budget: z.number().positive().optional(), view: z.string().optional(), amenity: z.string().optional() });
const appRouter = t.router({
  auth: t.router({ me: publicProcedure.query(() => null), logout: publicProcedure.mutation(() => ({ success: true as const })) }),
  staffAuth: t.router({
    me: publicProcedure.query(async ({ ctx }) => (await readStaff(ctx.req)) || null),
    login: publicProcedure.input(z.object({ username: z.string().trim().min(3).max(80), password: z.string().min(10).max(128) })).mutation(async ({ input, ctx }) => { const account = (await sql("select id,username,display_name as \"displayName\",staff_role as \"staffRole\",password_hash,password_salt,is_active from staff_accounts where username=$1 limit 1", [input.username.toLowerCase()]))[0]; if (!account || !account.is_active || !passwordMatches(input.password, account.password_salt, account.password_hash)) throw new TRPCError({ code: "UNAUTHORIZED", message: "Invalid username or password." }); const staff = { id: Number(account.id), username: account.username, displayName: account.displayName, staffRole: account.staffRole }; const token = await new SignJWT({ username: staff.username, displayName: staff.displayName, staffRole: staff.staffRole }).setProtectedHeader({ alg: "HS256" }).setSubject(String(staff.id)).setIssuedAt().setExpirationTime("8h").sign(jwtKey()); ctx.res.setHeader("Set-Cookie", sessionCookie(token)); return { ...staff, sessionToken: token }; }),
    logout: publicProcedure.mutation(({ ctx }) => { ctx.res.setHeader("Set-Cookie", serialize("bnakowa_staff_session", "", { httpOnly: true, secure: process.env.NODE_ENV === "production", sameSite: "lax", path: "/", maxAge: 0 })); return { success: true as const }; }),
  }),
  hotel: t.router({
    bootstrap: publicProcedure.query(async () => { await ensureDatabaseReady(); return { ready: true as const }; }),
    search: publicProcedure.input(inputSearch).query(({ input }) => searchRooms(input)),
    reserve: publicProcedure.input(z.object({ roomTypeId: z.number().int().positive(), checkIn: z.string(), checkOut: z.string(), adults: z.number().int().min(1).max(8), children: z.number().int().min(0).max(6), firstName: z.string().trim().min(2), lastName: z.string().trim().min(2), email: z.string().email(), phone: z.string().optional(), specialRequests: z.string().max(500).optional(), marketingOptIn: z.boolean().optional() })).mutation(({ input }) => createReservation(input)),
    operations: t.router({ dashboard: staffProcedure.query(() => dashboard()), analytics: staffProcedure.query(async () => ({ monthly: await analytics() })), reservationGuestCsv: staffProcedure.query(() => reservationCsv()), reservationStatus: staffProcedure.input(z.object({ id: z.number().positive(), status: z.enum(["pending", "confirmed", "checked_in", "checked_out", "cancelled", "no_show"]) })).mutation(async ({ input, ctx }) => { await sql("update reservations set status=$1,updated_at=now() where id=$2", [input.status, input.id]); await sql("insert into audit_events (actor_user_id,action,entity_type,entity_id,metadata) values ($1,'reservation.status_changed','reservation',$2,$3)", [ctx.staff!.id, input.id, JSON.stringify({ to: input.status })]); return { success: true as const }; }), taskStatus: staffProcedure.input(z.object({ id: z.number().positive(), status: z.enum(["open", "in_progress", "completed", "blocked"]) })).mutation(async ({ input, ctx }) => { await sql("update housekeeping_tasks set status=$1 where id=$2", [input.status, input.id]); await sql("insert into audit_events (actor_user_id,action,entity_type,entity_id,metadata) values ($1,'housekeeping.status_changed','housekeeping_task',$2,$3)", [ctx.staff!.id, input.id, JSON.stringify({ to: input.status })]); return { success: true as const }; }) }),
  }),
});
export type AppRouter = typeof appRouter;

const app = express();
app.set("trust proxy", 1);
app.use(express.json({ limit: "1mb" }));
app.get("/healthz", async (_req, res) => { try { await verifyDatabaseConnection(); res.status(200).json({ status: "ok" }); } catch (error) { res.status(503).json({ status: "unavailable", error: error instanceof Error ? error.message : "Database check failed" }); } });
app.use("/api/trpc", createExpressMiddleware({ router: appRouter, createContext: async ({ req, res }) => ({ req, res, staff: await readStaff(req) }), onError: ({ path: route, error }) => console.error(`[tRPC] ${route || "unknown"}: ${error.message}`) }));
app.use(express.static(PUBLIC_DIR, { index: false, maxAge: 0, etag: true }));
app.get("*", (_req, res) => res.sendFile(path.join(PUBLIC_DIR, "index.html"), error => { if (error) res.status(500).send("Client build not found. Run `npm run build:client` (or `npm run dev`) first."); }));

async function main() {
  await ensureDatabaseReady();
  const server = app.listen(PORT, "0.0.0.0", () => console.info(`B-NAKOWA listening on ${PORT}`));
  const close = () => server.close(() => pool.end().finally(() => process.exit(0)));
  process.once("SIGTERM", close); process.once("SIGINT", close);
}
main().catch(error => { console.error("Unable to start B-NAKOWA:", error); pool.end().finally(() => process.exit(1)); });
