CREATE TYPE "public"."housekeeping_priority" AS ENUM('low', 'normal', 'high', 'urgent');--> statement-breakpoint
CREATE TYPE "public"."housekeeping_status" AS ENUM('open', 'in_progress', 'completed', 'blocked');--> statement-breakpoint
CREATE TYPE "public"."housekeeping_task_type" AS ENUM('cleaning', 'inspection', 'maintenance', 'turndown');--> statement-breakpoint
CREATE TYPE "public"."loyalty_tier" AS ENUM('standard', 'silver', 'gold', 'platinum');--> statement-breakpoint
CREATE TYPE "public"."payment_method" AS ENUM('card', 'cash', 'bank_transfer', 'invoice');--> statement-breakpoint
CREATE TYPE "public"."payment_status" AS ENUM('authorized', 'captured', 'refunded', 'failed', 'pending');--> statement-breakpoint
CREATE TYPE "public"."reservation_source" AS ENUM('direct', 'phone', 'walk_in', 'ota', 'corporate');--> statement-breakpoint
CREATE TYPE "public"."reservation_status" AS ENUM('pending', 'confirmed', 'checked_in', 'checked_out', 'cancelled', 'no_show');--> statement-breakpoint
CREATE TYPE "public"."room_status" AS ENUM('available', 'maintenance', 'out_of_order');--> statement-breakpoint
CREATE TYPE "public"."staff_role" AS ENUM('owner', 'manager', 'front_desk', 'housekeeping', 'viewer');--> statement-breakpoint
CREATE TABLE "amenities" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(100) NOT NULL,
	"icon" varchar(32) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "audit_events" (
	"id" serial PRIMARY KEY NOT NULL,
	"actor_user_id" integer,
	"action" varchar(120) NOT NULL,
	"entity_type" varchar(80) NOT NULL,
	"entity_id" integer,
	"metadata" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "guests" (
	"id" serial PRIMARY KEY NOT NULL,
	"first_name" varchar(80) NOT NULL,
	"last_name" varchar(80) NOT NULL,
	"email" varchar(190) NOT NULL,
	"phone" varchar(40),
	"loyalty_tier" "loyalty_tier" DEFAULT 'standard' NOT NULL,
	"marketing_opt_in" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "housekeeping_tasks" (
	"id" serial PRIMARY KEY NOT NULL,
	"property_id" integer NOT NULL,
	"room_id" integer NOT NULL,
	"reservation_id" integer,
	"task_type" "housekeeping_task_type" DEFAULT 'cleaning' NOT NULL,
	"priority" "housekeeping_priority" DEFAULT 'normal' NOT NULL,
	"status" "housekeeping_status" DEFAULT 'open' NOT NULL,
	"assigned_to" varchar(120),
	"due_at" timestamp with time zone,
	"notes" varchar(255),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "payments" (
	"id" serial PRIMARY KEY NOT NULL,
	"reservation_id" integer NOT NULL,
	"amount" numeric(12, 2) NOT NULL,
	"method" "payment_method" DEFAULT 'card' NOT NULL,
	"status" "payment_status" DEFAULT 'pending' NOT NULL,
	"transaction_ref" varchar(120),
	"paid_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "properties" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" varchar(180) NOT NULL,
	"slug" varchar(80) NOT NULL,
	"code" varchar(24) NOT NULL,
	"address" varchar(255) NOT NULL,
	"city" varchar(100) NOT NULL,
	"region" varchar(100) NOT NULL,
	"country" varchar(100) NOT NULL,
	"timezone" varchar(64) NOT NULL,
	"currency" varchar(3) NOT NULL,
	"check_in_time" varchar(8) NOT NULL,
	"check_out_time" varchar(8) NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "reservation_rooms" (
	"id" serial PRIMARY KEY NOT NULL,
	"reservation_id" integer NOT NULL,
	"room_id" integer NOT NULL,
	"nightly_rate" numeric(12, 2) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "reservations" (
	"id" serial PRIMARY KEY NOT NULL,
	"reservation_code" varchar(24) NOT NULL,
	"property_id" integer NOT NULL,
	"guest_id" integer NOT NULL,
	"check_in" date NOT NULL,
	"check_out" date NOT NULL,
	"adults" integer NOT NULL,
	"children" integer DEFAULT 0 NOT NULL,
	"source" "reservation_source" DEFAULT 'direct' NOT NULL,
	"status" "reservation_status" DEFAULT 'pending' NOT NULL,
	"subtotal" numeric(12, 2) NOT NULL,
	"tax_amount" numeric(12, 2) NOT NULL,
	"total_amount" numeric(12, 2) NOT NULL,
	"special_requests" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "room_type_amenities" (
	"id" serial PRIMARY KEY NOT NULL,
	"room_type_id" integer NOT NULL,
	"amenity_id" integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE "room_types" (
	"id" serial PRIMARY KEY NOT NULL,
	"property_id" integer NOT NULL,
	"name" varchar(120) NOT NULL,
	"code" varchar(40) NOT NULL,
	"description" text NOT NULL,
	"base_rate" numeric(12, 2) NOT NULL,
	"max_occupancy" integer NOT NULL,
	"bed_configuration" varchar(120) NOT NULL,
	"size_sqm" numeric(7, 2) NOT NULL,
	"view_label" varchar(100) NOT NULL,
	"accent" varchar(32) DEFAULT 'sand' NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE "rooms" (
	"id" serial PRIMARY KEY NOT NULL,
	"property_id" integer NOT NULL,
	"room_type_id" integer NOT NULL,
	"room_number" varchar(24) NOT NULL,
	"floor" integer NOT NULL,
	"status" "room_status" DEFAULT 'available' NOT NULL
);
--> statement-breakpoint
CREATE TABLE "staff_accounts" (
	"id" serial PRIMARY KEY NOT NULL,
	"username" varchar(80) NOT NULL,
	"password_hash" varchar(128) NOT NULL,
	"password_salt" varchar(64) NOT NULL,
	"display_name" varchar(120) NOT NULL,
	"staff_role" "staff_role" DEFAULT 'viewer' NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
	--> statement-breakpoint
ALTER TABLE "housekeeping_tasks" ADD CONSTRAINT "housekeeping_tasks_property_id_properties_id_fk" FOREIGN KEY ("property_id") REFERENCES "public"."properties"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "housekeeping_tasks" ADD CONSTRAINT "housekeeping_tasks_room_id_rooms_id_fk" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "housekeeping_tasks" ADD CONSTRAINT "housekeeping_tasks_reservation_id_reservations_id_fk" FOREIGN KEY ("reservation_id") REFERENCES "public"."reservations"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "payments" ADD CONSTRAINT "payments_reservation_id_reservations_id_fk" FOREIGN KEY ("reservation_id") REFERENCES "public"."reservations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reservation_rooms" ADD CONSTRAINT "reservation_rooms_reservation_id_reservations_id_fk" FOREIGN KEY ("reservation_id") REFERENCES "public"."reservations"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reservation_rooms" ADD CONSTRAINT "reservation_rooms_room_id_rooms_id_fk" FOREIGN KEY ("room_id") REFERENCES "public"."rooms"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reservations" ADD CONSTRAINT "reservations_property_id_properties_id_fk" FOREIGN KEY ("property_id") REFERENCES "public"."properties"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reservations" ADD CONSTRAINT "reservations_guest_id_guests_id_fk" FOREIGN KEY ("guest_id") REFERENCES "public"."guests"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "room_type_amenities" ADD CONSTRAINT "room_type_amenities_room_type_id_room_types_id_fk" FOREIGN KEY ("room_type_id") REFERENCES "public"."room_types"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "room_type_amenities" ADD CONSTRAINT "room_type_amenities_amenity_id_amenities_id_fk" FOREIGN KEY ("amenity_id") REFERENCES "public"."amenities"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "room_types" ADD CONSTRAINT "room_types_property_id_properties_id_fk" FOREIGN KEY ("property_id") REFERENCES "public"."properties"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rooms" ADD CONSTRAINT "rooms_property_id_properties_id_fk" FOREIGN KEY ("property_id") REFERENCES "public"."properties"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "rooms" ADD CONSTRAINT "rooms_room_type_id_room_types_id_fk" FOREIGN KEY ("room_type_id") REFERENCES "public"."room_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "amenities_name_unique" ON "amenities" USING btree ("name");--> statement-breakpoint
CREATE INDEX "audit_entity_idx" ON "audit_events" USING btree ("entity_type","entity_id");--> statement-breakpoint
CREATE UNIQUE INDEX "guests_email_unique" ON "guests" USING btree ("email");--> statement-breakpoint
CREATE INDEX "housekeeping_property_status_idx" ON "housekeeping_tasks" USING btree ("property_id","status");--> statement-breakpoint
CREATE UNIQUE INDEX "properties_slug_unique" ON "properties" USING btree ("slug");--> statement-breakpoint
CREATE UNIQUE INDEX "properties_code_unique" ON "properties" USING btree ("code");--> statement-breakpoint
CREATE UNIQUE INDEX "reservation_room_unique" ON "reservation_rooms" USING btree ("reservation_id","room_id");--> statement-breakpoint
CREATE INDEX "reservation_rooms_room_idx" ON "reservation_rooms" USING btree ("room_id");--> statement-breakpoint
CREATE UNIQUE INDEX "reservations_code_unique" ON "reservations" USING btree ("reservation_code");--> statement-breakpoint
CREATE INDEX "reservations_property_dates_idx" ON "reservations" USING btree ("property_id","check_in","check_out");--> statement-breakpoint
CREATE INDEX "reservations_guest_idx" ON "reservations" USING btree ("guest_id");--> statement-breakpoint
CREATE UNIQUE INDEX "room_type_amenity_unique" ON "room_type_amenities" USING btree ("room_type_id","amenity_id");--> statement-breakpoint
CREATE UNIQUE INDEX "room_types_code_unique" ON "room_types" USING btree ("code");--> statement-breakpoint
CREATE INDEX "room_types_property_idx" ON "room_types" USING btree ("property_id");--> statement-breakpoint
CREATE UNIQUE INDEX "rooms_property_number_unique" ON "rooms" USING btree ("property_id","room_number");--> statement-breakpoint
CREATE INDEX "rooms_type_idx" ON "rooms" USING btree ("room_type_id");--> statement-breakpoint
CREATE UNIQUE INDEX "staff_accounts_username_unique" ON "staff_accounts" USING btree ("username");