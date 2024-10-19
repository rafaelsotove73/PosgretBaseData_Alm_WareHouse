
CREATE TABLE Proveedores (
ProveedorID SERIAL PRIMARY KEY,
Nombre VARCHAR(100) NOT NULL,
Apellido VARCHAR(100) NOT NULL,
RazonSocial VARCHAR(100) NOT NULL,
Direccion VARCHAR(255),
Telefono VARCHAR(20),
Email VARCHAR(100),
Contacto VARCHAR(100)
);


-- Tabla de Productos
CREATE TABLE Productos (
ProductoID SERIAL PRIMARY KEY,
Codigo VARCHAR(10) NOT NULL,
Nombre VARCHAR(100) NOT NULL,
Descripcion VARCHAR(255),
Precio DECIMAL(10, 2) NOT NULL,
Stock INT NOT NULL
);

-- Tabla para el encabezado del albarán
CREATE TABLE AlbaranCompraEncabezado (
AlbaranCompraID SERIAL PRIMARY KEY,
Fecha DATE NOT NULL,
ProveedorID INT NOT NULL,
Total DECIMAL(10, 2) NOT NULL,
Estado VARCHAR(50) NOT NULL DEFAULT 'Pendiente', -- Por ejemplo: Pendiente, Recibido, Facturado
Observaciones VARCHAR(255),
CONSTRAINT FK_Proveedor FOREIGN KEY (ProveedorID) REFERENCES Proveedores(ProveedorID)
);

-- Tabla para los detalles del albarán
CREATE TABLE AlbaranCompraDetalle (
DetalleID SERIAL PRIMARY KEY,
AlbaranCompraID INT NOT NULL,
ProductoID INT NOT NULL,
Cantidad INT NOT NULL,
PrecioCompra DECIMAL(10, 2) NOT NULL, -- Precio de compra del producto
Subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (Cantidad * PrecioCompra) STORED,  -- Cálculo automático del subtotal
CONSTRAINT FK_AlbaranCompra FOREIGN KEY (AlbaranCompraID) REFERENCES AlbaranCompraEncabezado(AlbaranCompraID),
CONSTRAINT FK_Producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);

-- Índices recomendados
CREATE INDEX IX_AlbaranCompraEncabezado_Fecha ON AlbaranCompraEncabezado (Fecha);
CREATE INDEX IX_AlbaranCompraDetalle_ProductoID ON AlbaranCompraDetalle (ProductoID);

-- Trigger para actualizar el total en AlbaranCompraEncabezado al insertar o actualizar detalles
CREATE OR REPLACE FUNCTION trg_ActualizarTotalAlbaranCompra()
RETURNS TRIGGER AS $$
BEGIN
UPDATE AlbaranCompraEncabezado
SET Total = (
SELECT SUM(Cantidad * PrecioCompra)
FROM AlbaranCompraDetalle
WHERE AlbaranCompraID = NEW.AlbaranCompraID
)
WHERE AlbaranCompraID = NEW.AlbaranCompraID;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ActualizarTotalAlbaranCompra
AFTER INSERT OR UPDATE OR DELETE ON AlbaranCompraDetalle
FOR EACH ROW EXECUTE FUNCTION trg_ActualizarTotalAlbaranCompra();

-- ======================================
-- ======================================

CREATE TABLE Almacenes (
AlmacenID SERIAL PRIMARY KEY,
Codigo VARCHAR(10) NOT NULL,
Nombre VARCHAR(100) NOT NULL,
Direccion VARCHAR(255)
);

-- Tabla de Estanterías (cada estante dentro de un almacén)
CREATE TABLE Estanterias (
EstanteriaID SERIAL PRIMARY KEY,
Codigo VARCHAR(10) NOT NULL,
AlmacenID INT NOT NULL,
Descripcion VARCHAR(100), -- Por ejemplo: "Estante A", "Estante B"
CONSTRAINT FK_Almacen FOREIGN KEY (AlmacenID) REFERENCES Almacenes(AlmacenID)
);

-- Tabla de Ubicaciones en los estantes (niveles y tramos dentro de cada estante)
CREATE TABLE Ubicaciones (
UbicacionID SERIAL PRIMARY KEY,
Codigo VARCHAR(10) NOT NULL,
EstanteriaID INT NOT NULL,
Nivel INT NOT NULL,  -- Nivel dentro del estante (por ejemplo, nivel 1, nivel 2)
Tramo INT NOT NULL,  -- Tramo dentro del nivel (por ejemplo, tramo 1, tramo 2)
CONSTRAINT FK_Estanteria FOREIGN KEY (EstanteriaID) REFERENCES Estanterias(EstanteriaID)
);

-- Tabla para el inventario de productos en almacenes (ubicación y cantidad)
CREATE TABLE Inventario (
InventarioID SERIAL PRIMARY KEY,
ProductoID INT NOT NULL,
UbicacionID INT NOT NULL,
Cantidad INT NOT NULL,
CONSTRAINT FK_Product FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID),
CONSTRAINT FK_Ubicacion FOREIGN KEY (UbicacionID) REFERENCES Ubicaciones(UbicacionID)
);

-- ====================================================

-- Tabla de Trabajadores (humanos que realizan movimientos en el almacén)
CREATE TABLE Trabajadores (
TrabajadorID SERIAL PRIMARY KEY,
Nombre VARCHAR(100) NOT NULL,
Apellido VARCHAR(100) NOT NULL,
Cargo VARCHAR(50) -- Cargo dentro de la empresa (ejemplo: Operador, Supervisor)
);

-- Tabla de Tipos de Bot
CREATE TABLE TiposBot (
TipoBotID SERIAL PRIMARY KEY,
Descripcion VARCHAR(100) NOT NULL  -- Descripción del tipo de bot (ejemplo: Recepción, Entrada, Salida, Movimiento)
);

-- Tabla de Bots (con serial)
CREATE TABLE Bots (
BotID SERIAL PRIMARY KEY,
CodigoBot VARCHAR(50) NOT NULL,  -- Identificador del bot
Serial VARCHAR(100) NOT NULL,    -- Serial único del bot
TipoBotID INT NOT NULL,
CONSTRAINT FK_TipoBot FOREIGN KEY (TipoBotID) REFERENCES TiposBot(TipoBotID)
);

-- Tabla de Tipos de Movimiento (Entrada, Salida, Movimiento)
CREATE TABLE TiposMovimiento (
TipoMovimientoID SERIAL PRIMARY KEY,
Descripcion VARCHAR(100) NOT NULL  -- Ejemplo: "Entrada", "Salida", "Movimiento Interno"
);

-- Tabla de Movimientos de Almacén
CREATE TABLE MovimientosAlmacen (
MovimientoID SERIAL PRIMARY KEY,
Fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
ProductoID INT NOT NULL,
TipoMovimientoID INT NOT NULL,
UbicacionOrigenID INT NULL,  -- Solo para movimientos o salidas
UbicacionDestinoID INT NULL, -- Solo para entradas o movimientos
Cantidad INT NOT NULL,
TrabajadorID INT NULL,  -- El trabajador que realizó la operación (si fue humano)
BotID INT NULL,         -- El bot que realizó la operación (si fue automático)
Observaciones VARCHAR(255),  -- Detalles adicionales del movimiento
CONSTRAINT FK_ProductoMovimiento FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID),
CONSTRAINT FK_TipoMovimiento FOREIGN KEY (TipoMovimientoID) REFERENCES TiposMovimiento(TipoMovimientoID),
CONSTRAINT FK_UbicacionOrigen FOREIGN KEY (UbicacionOrigenID) REFERENCES Ubicaciones(UbicacionID),
CONSTRAINT FK_UbicacionDestino FOREIGN KEY (UbicacionDestinoID) REFERENCES Ubicaciones(UbicacionID),
CONSTRAINT FK_Trabajador FOREIGN KEY (TrabajadorID) REFERENCES Trabajadores(TrabajadorID),
CONSTRAINT FK_Bot FOREIGN KEY (BotID) REFERENCES Bots(BotID)
);

-- Índice para mejorar las consultas por fecha
CREATE INDEX IX_MovimientosAlmacen_Fecha ON MovimientosAlmacen(Fecha);

-- ====================================================
-- ====================================================
-- ====================================================

