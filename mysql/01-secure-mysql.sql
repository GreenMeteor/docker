-- Delete anonymous users
DELETE FROM mysql.user WHERE User='';

-- Delete remote root access
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Drop test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Apply additional security settings
UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';

-- Flush privileges
FLUSH PRIVILEGES;
