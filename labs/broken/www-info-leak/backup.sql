# Base de datos - EXPORT
# Fecha: 2024-01-15
CREATE TABLE usuarios (
    id INT PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    password_hash VARCHAR(255)
);
INSERT INTO usuarios VALUES (1, 'admin', 'admin@empresa.com', '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8');
