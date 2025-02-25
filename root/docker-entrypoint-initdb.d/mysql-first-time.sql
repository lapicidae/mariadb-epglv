CREATE DATABASE IF NOT EXISTS epg2vdr charset utf8mb4;

GRANT ALL PRIVILEGES ON epg2vdr.* TO 'epg2vdr'@'%' IDENTIFIED BY 'epg';
GRANT ALL PRIVILEGES ON epg2vdr.* TO 'epg2vdr'@'localhost' IDENTIFIED BY 'epg';
FLUSH PRIVILEGES;

-- set svg as logoSuffix for epghttpd
USE epg2vdr;

CREATE TABLE IF NOT EXISTS `parameters` (
  `owner` varchar(40) NOT NULL,
  `name` varchar(40) NOT NULL,
  `inssp` int(11) DEFAULT NULL,
  `updsp` int(11) DEFAULT NULL,
  `value` varchar(500) DEFAULT NULL
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

INSERT INTO `parameters` (`owner`, `name`, `inssp`, `updsp`, `value`) VALUES
('epgd', 'logoSuffix', 0, 0, 'svg');

ALTER TABLE `parameters`
  ADD PRIMARY KEY (`owner`,`name`);
COMMIT;

-- create functions
DROP FUNCTION IF EXISTS epglv;
DROP FUNCTION IF EXISTS epglvr;
CREATE FUNCTION epglv RETURNS INT SONAME 'mysqlepglv.so';
CREATE FUNCTION epglvr RETURNS INT SONAME 'mysqlepglv.so';

