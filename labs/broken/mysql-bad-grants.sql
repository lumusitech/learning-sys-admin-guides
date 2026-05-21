-- MySQL con problemas de grants
-- Crear usuario sin permisos reales
CREATE USER 'deploy'@'%' IDENTIFIED BY 'deploy123';
-- Error: se olvidaron de hacer GRANT, el usuario existe pero no puede hacer nada

-- Error: root sin password (solo para lab)
ALTER USER 'root'@'%' IDENTIFIED BY '';
FLUSH PRIVILEGES;

-- Error: base de datos con grants rotos
CREATE DATABASE app;
CREATE USER 'appuser'@'%' IDENTIFIED BY 'apppass';
-- Error: GRANT a tabla que no existe todavía
GRANT ALL PRIVILEGES ON app.nonexistent.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
