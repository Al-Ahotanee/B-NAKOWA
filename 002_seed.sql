-- B-NAKOWA seed data for a fresh Neon database.
-- Staff accounts are created by the application from BNAKOWA_ADMIN_USERNAME and BNAKOWA_ADMIN_PASSWORD.
BEGIN;
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: amenities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.amenities (id, name, icon) VALUES (1, 'High-speed Wi-Fi', 'wifi');
INSERT INTO public.amenities (id, name, icon) VALUES (2, 'Breakfast service', 'coffee');
INSERT INTO public.amenities (id, name, icon) VALUES (3, 'Air conditioning', 'snowflake');
INSERT INTO public.amenities (id, name, icon) VALUES (4, 'Smart TV', 'tv');
INSERT INTO public.amenities (id, name, icon) VALUES (5, 'Workspace', 'briefcase');
INSERT INTO public.amenities (id, name, icon) VALUES (6, 'Airport pickup', 'car');
INSERT INTO public.amenities (id, name, icon) VALUES (7, 'Private terrace', 'sun');
INSERT INTO public.amenities (id, name, icon) VALUES (8, 'Family lounge', 'armchair');


--
-- Data for Name: audit_events; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.audit_events (id, actor_user_id, action, entity_type, entity_id, metadata, created_at) VALUES (1, NULL, 'reservation.created', 'reservation', 1, '{"source": "direct", "channel": "web"}', '2026-08-25 14:40:08.265611+00');
INSERT INTO public.audit_events (id, actor_user_id, action, entity_type, entity_id, metadata, created_at) VALUES (2, NULL, 'reservation.status_changed', 'reservation', 2, '{"to": "checked_in", "from": "confirmed"}', '2026-08-25 14:40:08.265611+00');
INSERT INTO public.audit_events (id, actor_user_id, action, entity_type, entity_id, metadata, created_at) VALUES (3, NULL, 'reservation.verified', 'reservation', 4, '{"note": "Verified legacy test reservation retained"}', '2026-08-25 14:40:08.265611+00');


--
-- Data for Name: guests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.guests (id, first_name, last_name, email, phone, loyalty_tier, marketing_opt_in, created_at) VALUES (1, 'Amina', 'Muhammad', 'amina.muhammad@example.com', '+234 803 111 2290', 'gold', true, '2026-08-25 14:40:08.253114+00');
INSERT INTO public.guests (id, first_name, last_name, email, phone, loyalty_tier, marketing_opt_in, created_at) VALUES (2, 'Ibrahim', 'Sani', 'ibrahim.sani@example.com', '+234 806 222 3401', 'silver', false, '2026-08-25 14:40:08.253114+00');
INSERT INTO public.guests (id, first_name, last_name, email, phone, loyalty_tier, marketing_opt_in, created_at) VALUES (3, 'Zainab', 'Bello', 'zainab.bello@example.com', '+234 809 333 4452', 'standard', true, '2026-08-25 14:40:08.253114+00');
INSERT INTO public.guests (id, first_name, last_name, email, phone, loyalty_tier, marketing_opt_in, created_at) VALUES (4, 'Amelia', 'Stone', 'amelia.stone@example.com', '+44 7700 900555', 'standard', false, '2026-08-25 14:40:08.253114+00');
INSERT INTO public.guests (id, first_name, last_name, email, phone, loyalty_tier, marketing_opt_in, created_at) VALUES (5, 'Sofia', 'Bennett', 'sofia.bennett@example.com', '+44 7700 900121', 'gold', true, '2026-08-25 14:40:08.253114+00');


--
-- Data for Name: properties; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.properties (id, name, slug, code, address, city, region, country, timezone, currency, check_in_time, check_out_time, is_active, created_at) VALUES (1, 'B-NAKOWA MODERN GUEST HOUSE', 'b-nakowa', 'BNK-DUT', 'Dutse, Jigawa State', 'Dutse', 'Jigawa State', 'Nigeria', 'Africa/Lagos', 'NGN', '14:00', '12:00', true, '2026-08-25 14:40:08.23017+00');
INSERT INTO public.properties (id, name, slug, code, address, city, region, country, timezone, currency, check_in_time, check_out_time, is_active, created_at) VALUES (2, 'Lumina Grand Hotel', 'lumina-grand-legacy', 'LUM-GRD', '1 Crescent Quay, Canary Wharf', 'London', 'Greater London', 'United Kingdom', 'Europe/London', 'GBP', '15:00', '11:00', false, '2026-08-25 14:40:08.23017+00');


--
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reservations (id, reservation_code, property_id, guest_id, check_in, check_out, adults, children, source, status, subtotal, tax_amount, total_amount, special_requests, created_at, updated_at) VALUES (1, 'BNK-7F3Q2M', 1, 1, '2026-08-24', '2026-08-27', 2, 0, 'direct', 'confirmed', 66000.00, 4950.00, 70950.00, 'Late arrival requested', '2026-08-25 14:40:08.256096+00', '2026-08-25 14:40:08.256096+00');
INSERT INTO public.reservations (id, reservation_code, property_id, guest_id, check_in, check_out, adults, children, source, status, subtotal, tax_amount, total_amount, special_requests, created_at, updated_at) VALUES (2, 'BNK-5R8L1C', 1, 2, '2026-08-23', '2026-08-25', 1, 0, 'phone', 'checked_in', 68000.00, 5100.00, 73100.00, 'Quiet floor preferred', '2026-08-25 14:40:08.256096+00', '2026-08-25 14:40:08.256096+00');
INSERT INTO public.reservations (id, reservation_code, property_id, guest_id, check_in, check_out, adults, children, source, status, subtotal, tax_amount, total_amount, special_requests, created_at, updated_at) VALUES (3, 'BNK-9T4A6D', 1, 3, '2026-08-29', '2026-09-02', 2, 1, 'corporate', 'pending', 192000.00, 14400.00, 206400.00, 'Family arrival setup', '2026-08-25 14:40:08.256096+00', '2026-08-25 14:40:08.256096+00');
INSERT INTO public.reservations (id, reservation_code, property_id, guest_id, check_in, check_out, adults, children, source, status, subtotal, tax_amount, total_amount, special_requests, created_at, updated_at) VALUES (4, 'LUM-002EF2', 2, 4, '2026-08-24', '2026-08-26', 2, 0, 'direct', 'confirmed', 378.00, 75.60, 453.60, 'Verified legacy test reservation', '2026-08-25 14:40:08.256096+00', '2026-08-25 14:40:08.256096+00');
INSERT INTO public.reservations (id, reservation_code, property_id, guest_id, check_in, check_out, adults, children, source, status, subtotal, tax_amount, total_amount, special_requests, created_at, updated_at) VALUES (5, 'LUM-8Q2K7M', 2, 5, '2026-08-24', '2026-08-27', 2, 0, 'direct', 'confirmed', 567.00, 113.40, 680.40, 'Late arrival after 21:00', '2026-08-25 14:40:08.256096+00', '2026-08-25 14:40:08.256096+00');


--
-- Data for Name: room_types; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.room_types (id, property_id, name, code, description, base_rate, max_occupancy, bed_configuration, size_sqm, view_label, accent, is_active) VALUES (1, 1, 'Classic Queen', 'BNK-CLASSIC', 'A serene, air-conditioned room with a queen bed, dedicated work surface and restful palette.', 22000.00, 2, '1 queen bed', 25.00, 'Dutse city view', 'sand', true);
INSERT INTO public.room_types (id, property_id, name, code, description, base_rate, max_occupancy, bed_configuration, size_sqm, view_label, accent, is_active) VALUES (2, 1, 'Executive King', 'BNK-EXEC', 'A generous contemporary room with a king bed, lounge chair and elevated in-room comforts.', 34000.00, 2, '1 king bed', 33.00, 'Quiet courtyard', 'olive', true);
INSERT INTO public.room_types (id, property_id, name, code, description, base_rate, max_occupancy, bed_configuration, size_sqm, view_label, accent, is_active) VALUES (3, 1, 'Family Residence', 'BNK-FAMILY', 'A flexible two-zone suite with space to slow down, share meals and travel together easily.', 48000.00, 4, '1 queen + sofa bed', 51.00, 'Garden terrace', 'terracotta', true);
INSERT INTO public.room_types (id, property_id, name, code, description, base_rate, max_occupancy, bed_configuration, size_sqm, view_label, accent, is_active) VALUES (4, 2, 'Urban King', 'LUM-URBAN', 'A calm, light-filled city room designed for short stays and considered work.', 189.00, 2, '1 king bed', 28.00, 'City skyline', 'indigo', true);
INSERT INTO public.room_types (id, property_id, name, code, description, base_rate, max_occupancy, bed_configuration, size_sqm, view_label, accent, is_active) VALUES (5, 2, 'Executive Twin', 'LUM-TWIN', 'Flexible twin accommodation with club-floor comfort and a generous desk.', 229.00, 3, '2 twin beds', 34.00, 'River glimpse', 'teal', true);


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (1, 1, 1, '101', 1, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (2, 1, 1, '102', 1, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (3, 1, 1, '103', 1, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (4, 1, 1, '104', 1, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (5, 1, 2, '201', 2, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (6, 1, 2, '202', 2, 'maintenance');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (7, 1, 2, '203', 2, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (8, 1, 2, '204', 2, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (9, 1, 3, '301', 3, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (10, 1, 3, '302', 3, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (11, 1, 3, '303', 3, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (12, 1, 3, '304', 3, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (13, 2, 4, '101', 1, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (14, 2, 4, '102', 1, 'available');
INSERT INTO public.rooms (id, property_id, room_type_id, room_number, floor, status) VALUES (15, 2, 5, '301', 3, 'available');


--
-- Data for Name: housekeeping_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.housekeeping_tasks (id, property_id, room_id, reservation_id, task_type, priority, status, assigned_to, due_at, notes, created_at) VALUES (1, 1, 1, 1, 'inspection', 'high', 'open', 'Housekeeping team', '2026-08-24 12:00:00+00', 'Arrival inspection before 14:00 check-in', '2026-08-25 14:40:08.263909+00');
INSERT INTO public.housekeeping_tasks (id, property_id, room_id, reservation_id, task_type, priority, status, assigned_to, due_at, notes, created_at) VALUES (2, 1, 9, 3, 'cleaning', 'normal', 'open', 'Housekeeping team', '2026-08-29 12:00:00+00', 'Family arrival setup', '2026-08-25 14:40:08.263909+00');
INSERT INTO public.housekeeping_tasks (id, property_id, room_id, reservation_id, task_type, priority, status, assigned_to, due_at, notes, created_at) VALUES (3, 1, 5, 2, 'turndown', 'normal', 'completed', 'Evening service', '2026-08-23 18:00:00+00', 'Guest currently in-house', '2026-08-25 14:40:08.263909+00');
INSERT INTO public.housekeeping_tasks (id, property_id, room_id, reservation_id, task_type, priority, status, assigned_to, due_at, notes, created_at) VALUES (4, 2, 14, 4, 'inspection', 'high', 'completed', 'Legacy operations', '2026-08-24 13:30:00+00', 'Verified legacy reservation arrival inspection', '2026-08-25 14:40:08.263909+00');


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.payments (id, reservation_id, amount, method, status, transaction_ref, paid_at) VALUES (1, 1, 70950.00, 'card', 'captured', 'bnk_demo_7f3q2m', '2026-08-20 13:15:00+00');
INSERT INTO public.payments (id, reservation_id, amount, method, status, transaction_ref, paid_at) VALUES (2, 2, 73100.00, 'cash', 'captured', 'bnk_demo_5r8l1c', '2026-08-22 16:04:00+00');
INSERT INTO public.payments (id, reservation_id, amount, method, status, transaction_ref, paid_at) VALUES (3, 3, 206400.00, 'invoice', 'pending', 'bnk_inv_2026_88', NULL);
INSERT INTO public.payments (id, reservation_id, amount, method, status, transaction_ref, paid_at) VALUES (4, 4, 453.60, 'card', 'captured', 'demo_lum_002ef2', '2026-08-23 10:43:00+00');
INSERT INTO public.payments (id, reservation_id, amount, method, status, transaction_ref, paid_at) VALUES (5, 5, 680.40, 'card', 'captured', 'demo_lum_8q2k7m', '2026-08-20 13:15:00+00');


--
-- Data for Name: reservation_rooms; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.reservation_rooms (id, reservation_id, room_id, nightly_rate) VALUES (1, 1, 1, 22000.00);
INSERT INTO public.reservation_rooms (id, reservation_id, room_id, nightly_rate) VALUES (2, 2, 5, 34000.00);
INSERT INTO public.reservation_rooms (id, reservation_id, room_id, nightly_rate) VALUES (3, 3, 9, 48000.00);
INSERT INTO public.reservation_rooms (id, reservation_id, room_id, nightly_rate) VALUES (4, 4, 14, 189.00);
INSERT INTO public.reservation_rooms (id, reservation_id, room_id, nightly_rate) VALUES (5, 5, 13, 189.00);


--
-- Data for Name: room_type_amenities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (1, 1, 1);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (2, 1, 2);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (3, 1, 3);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (4, 1, 4);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (5, 1, 5);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (6, 2, 1);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (7, 2, 2);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (8, 2, 3);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (9, 2, 4);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (10, 2, 5);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (11, 2, 6);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (12, 3, 1);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (13, 3, 2);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (14, 3, 3);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (15, 3, 8);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (16, 3, 7);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (17, 4, 1);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (18, 4, 2);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (19, 4, 4);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (20, 4, 5);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (21, 5, 1);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (22, 5, 2);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (23, 5, 4);
INSERT INTO public.room_type_amenities (id, room_type_id, amenity_id) VALUES (24, 5, 5);


--
-- Data for Name: staff_accounts; Type: TABLE DATA; Schema: public; Owner: -
--






--
-- Name: amenities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.amenities_id_seq', 8, true);


--
-- Name: audit_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_events_id_seq', 13, true);


--
-- Name: guests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.guests_id_seq', 15, true);


--
-- Name: housekeeping_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.housekeeping_tasks_id_seq', 4, true);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.payments_id_seq', 15, true);


--
-- Name: properties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.properties_id_seq', 2, true);


--
-- Name: reservation_rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reservation_rooms_id_seq', 15, true);


--
-- Name: reservations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reservations_id_seq', 15, true);


--
-- Name: room_type_amenities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.room_type_amenities_id_seq', 24, true);


--
-- Name: room_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.room_types_id_seq', 5, true);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rooms_id_seq', 15, true);


--
-- Name: staff_accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.staff_accounts_id_seq', 1, false);


--


--
-- PostgreSQL database dump complete
--


COMMIT;
