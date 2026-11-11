-- Per-user playback progress. Server playback position stays wall-clock derived
-- (the server is the clock); this table only records personal watch progress.
CREATE TABLE IF NOT EXISTS watch_progress (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  screening_id INT UNSIGNED NOT NULL,
  movie_id INT UNSIGNED NOT NULL,
  position_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  duration_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  completed TINYINT(1) NOT NULL DEFAULT 0,
  last_watched_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uniq_watch_user_screening (user_id, screening_id),
  KEY idx_watch_movie (movie_id),
  KEY idx_watch_last (last_watched_at),
  KEY idx_watch_screening (screening_id),
  CONSTRAINT fk_watch_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_watch_screening FOREIGN KEY (screening_id) REFERENCES screenings (id) ON DELETE CASCADE,
  CONSTRAINT fk_watch_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;
