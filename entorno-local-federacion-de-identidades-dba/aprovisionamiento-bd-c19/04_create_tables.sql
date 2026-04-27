-- =============================================================================
-- 04_create_tables.sql
-- Crea tablas y datos de prueba en los schemas de aplicacion
-- Ejecutar como: sqlplus / as sysdba @04_create_tables.sql
-- =============================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- =============================================
-- Tablas en APP_VENTAS
-- =============================================

CREATE TABLE app_ventas.clientes (
  cliente_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  rut          VARCHAR2(12) NOT NULL UNIQUE,
  nombre       VARCHAR2(100) NOT NULL,
  email        VARCHAR2(100),
  fecha_alta   DATE DEFAULT SYSDATE
);

CREATE TABLE app_ventas.productos (
  producto_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo       VARCHAR2(20) NOT NULL UNIQUE,
  nombre       VARCHAR2(100) NOT NULL,
  precio       NUMBER(12,2) NOT NULL,
  activo       CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N'))
);

CREATE TABLE app_ventas.ordenes (
  orden_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cliente_id   NUMBER NOT NULL REFERENCES app_ventas.clientes(cliente_id),
  fecha        DATE DEFAULT SYSDATE,
  total        NUMBER(14,2),
  estado       VARCHAR2(20) DEFAULT 'PENDIENTE'
);

CREATE TABLE app_ventas.detalle_ordenes (
  detalle_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  orden_id     NUMBER NOT NULL REFERENCES app_ventas.ordenes(orden_id),
  producto_id  NUMBER NOT NULL REFERENCES app_ventas.productos(producto_id),
  cantidad     NUMBER(8) NOT NULL,
  precio_unit  NUMBER(12,2) NOT NULL
);

-- Vista de resumen
CREATE OR REPLACE VIEW app_ventas.v_resumen_ventas AS
  SELECT c.nombre cliente, o.fecha, o.total, o.estado
  FROM app_ventas.ordenes o
  JOIN app_ventas.clientes c ON c.cliente_id = o.cliente_id;

-- =============================================
-- Tablas en APP_INVENTARIO
-- =============================================

CREATE TABLE app_inventario.bodegas (
  bodega_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre       VARCHAR2(60) NOT NULL,
  ubicacion    VARCHAR2(100)
);

CREATE TABLE app_inventario.stock (
  stock_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  bodega_id    NUMBER NOT NULL REFERENCES app_inventario.bodegas(bodega_id),
  codigo_prod  VARCHAR2(20) NOT NULL,
  cantidad     NUMBER(10) NOT NULL,
  fecha_upd    DATE DEFAULT SYSDATE
);

-- =============================================
-- Tablas en APP_REPORTES
-- =============================================

CREATE TABLE app_reportes.log_consultas (
  log_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario      VARCHAR2(30),
  reporte      VARCHAR2(60),
  fecha        TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- =============================================
-- Datos de prueba
-- =============================================

-- Clientes
INSERT INTO app_ventas.clientes (rut, nombre, email) VALUES ('11111111-1', 'Empresa Alpha SpA', 'contacto@alpha.cl');
INSERT INTO app_ventas.clientes (rut, nombre, email) VALUES ('22222222-2', 'Comercial Beta Ltda', 'info@beta.cl');
INSERT INTO app_ventas.clientes (rut, nombre, email) VALUES ('33333333-3', 'Servicios Gamma SA', 'ventas@gamma.cl');

-- Productos
INSERT INTO app_ventas.productos (codigo, nombre, precio) VALUES ('PROD-001', 'Terminal POS', 150000.00);
INSERT INTO app_ventas.productos (codigo, nombre, precio) VALUES ('PROD-002', 'Lector QR', 45000.00);
INSERT INTO app_ventas.productos (codigo, nombre, precio) VALUES ('PROD-003', 'Impresora Boletas', 89000.00);

-- Ordenes
INSERT INTO app_ventas.ordenes (cliente_id, total, estado) VALUES (1, 195000.00, 'COMPLETADA');
INSERT INTO app_ventas.ordenes (cliente_id, total, estado) VALUES (2, 45000.00, 'PENDIENTE');

-- Detalle
INSERT INTO app_ventas.detalle_ordenes (orden_id, producto_id, cantidad, precio_unit) VALUES (1, 1, 1, 150000.00);
INSERT INTO app_ventas.detalle_ordenes (orden_id, producto_id, cantidad, precio_unit) VALUES (1, 2, 1, 45000.00);
INSERT INTO app_ventas.detalle_ordenes (orden_id, producto_id, cantidad, precio_unit) VALUES (2, 2, 1, 45000.00);

-- Bodegas y stock
INSERT INTO app_inventario.bodegas (nombre, ubicacion) VALUES ('Bodega Central', 'Santiago');
INSERT INTO app_inventario.bodegas (nombre, ubicacion) VALUES ('Bodega Sur', 'Concepcion');
INSERT INTO app_inventario.stock (bodega_id, codigo_prod, cantidad) VALUES (1, 'PROD-001', 500);
INSERT INTO app_inventario.stock (bodega_id, codigo_prod, cantidad) VALUES (1, 'PROD-002', 1200);
INSERT INTO app_inventario.stock (bodega_id, codigo_prod, cantidad) VALUES (2, 'PROD-003', 300);

COMMIT;

PROMPT >>> Tablas y datos de prueba creados exitosamente.
EXIT;
