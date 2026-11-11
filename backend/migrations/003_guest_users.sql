-- Guest users: nullable email (multiple NULLs are allowed by the UNIQUE index),
-- plus a flag and the IP used at creation for lightweight throttling.
ALTER TABLE users
  MODIFY email VARCHAR(190) NULL DEFAULT NULL,
  ADD COLUMN is_guest TINYINT(1) NOT NULL DEFAULT 0 AFTER is_active,
  ADD COLUMN guest_ip VARCHAR(45) NOT NULL DEFAULT '' AFTER is_guest;

ALTER TABLE users
  ADD KEY idx_users_guest_ip (guest_ip, created_at);
