/*
    1) Eliminar la BD en caso de existir
*/
IF DB_ID('DBArte') IS NOT NULL
BEGIN
    ALTER DATABASE DBArte SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DBArte;
END;
GO

/*
    2) Crear la base de datos e iniciar su uso
*/
CREATE DATABASE DBArte;
GO
USE DBArte;
GO

/*
    3) Creación de las tablas base (sin dependencias cruzadas o que referencien otras tablas).
       El orden de creación se establece para no romper referencias:
         - Pais
         - Region
         - Ciudad
         - Direccion
         - CategoriaArte
         - SubCategoriaArte
         - Artista
         - MetodoPago
         - MetodoEnvio
         - Fecha
*/

CREATE TABLE Pais (
    PaisId          INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          VARCHAR(50) NOT NULL,
    Continente      VARCHAR(50) NOT NULL,
    CONSTRAINT UQ_Pais_Nombre UNIQUE (Nombre),
    /* Restricción para evitar dígitos en el campo Nombre */
    CONSTRAINT CH_Pais_NombreNoDigitos CHECK (Nombre NOT LIKE '%[0-9]%')
);

CREATE TABLE Region (
    RegionId        INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          VARCHAR(100) NOT NULL,
    PaisId          INT         NOT NULL,
    CONSTRAINT FK_Region_Pais 
        FOREIGN KEY (PaisId) REFERENCES Pais(PaisId)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    /* Restricción para evitar dígitos en el campo Nombre */
    CONSTRAINT CH_Region_NombreNoDigitos CHECK (Nombre NOT LIKE '%[0-9]%')
);

CREATE TABLE Ciudad (
    CiudadId        INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          VARCHAR(100) NOT NULL,
    RegionId        INT          NOT NULL,
    CONSTRAINT FK_Ciudad_Region 
        FOREIGN KEY (RegionId) REFERENCES Region(RegionId)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    /* Restricción para evitar dígitos en el campo Nombre */
    CONSTRAINT CH_Ciudad_NombreNoDigitos CHECK (Nombre NOT LIKE '%[0-9]%')
);

CREATE TABLE Direccion (
    DireccionId INT IDENTITY(1,1) PRIMARY KEY,
    Calle       VARCHAR(200) NOT NULL,
    Numero      VARCHAR(20)  NOT NULL,
    CodigoPostal VARCHAR(20) NOT NULL,
    CiudadId    INT          NOT NULL,
    CONSTRAINT FK_Direccion_Ciudad 
        FOREIGN KEY (CiudadId) REFERENCES Ciudad(CiudadId)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    /* Restricción para 'Numero' (sólo dígitos) */
    CONSTRAINT CH_Direccion_NumeroSoloDigitos CHECK (Numero NOT LIKE '%[^0-9]%')
);

CREATE TABLE CategoriaArte (
    CategoriaArteId   INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria   VARCHAR(100) NOT NULL
);

CREATE TABLE SubCategoriaArte (
    SubCategoriaArteId    INT IDENTITY(1,1) PRIMARY KEY,
    NombreSubCategoria    VARCHAR(100) NOT NULL,
    CategoriaArteId       INT          NOT NULL,
    CONSTRAINT FK_SubCategoriaArte_CategoriaArte 
        FOREIGN KEY (CategoriaArteId) REFERENCES CategoriaArte(CategoriaArteId),
    /* Restricción para evitar dígitos en el campo NombreSubCategoria */
    CONSTRAINT CH_SubCategoriaArte_NombreNoDigitos CHECK (NombreSubCategoria NOT LIKE '%[0-9]%')
);

CREATE TABLE Artista (
    ArtistaId       INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          VARCHAR(100) NOT NULL,
    Apellido        VARCHAR(100) NOT NULL,
    Nacionalidad    VARCHAR(100) NOT NULL,
    /* Restricciones para evitar dígitos en Nombre y Apellido */
    CONSTRAINT CH_Artista_NombreNoDigitos CHECK (Nombre NOT LIKE '%[0-9]%'),
    CONSTRAINT CH_Artista_ApellidoNoDigitos CHECK (Apellido NOT LIKE '%[0-9]%')
);

CREATE TABLE MetodoPago (
    MetodoPagoId INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion  VARCHAR(50) NOT NULL,
    /* Restricción para evitar dígitos en la descripción (opcional) */
    CONSTRAINT CH_MetodoPago_DescNoDigits CHECK (Descripcion NOT LIKE '%[0-9]%')
);

CREATE TABLE MetodoEnvio (
    MetodoEnvioId INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion   VARCHAR(50) NOT NULL,
    TiempoEstimado VARCHAR(50) NOT NULL,
    /* Ejemplo: 'Courier Internacional', 'Courier Local', 'Recogida en Tienda', etc. */
    CONSTRAINT CH_MetodoEnvio_DescNoDigits CHECK (Descripcion NOT LIKE '%[0-9]%')
);

CREATE TABLE Fecha (
    FechaId  INT IDENTITY(1,1) PRIMARY KEY,
    Fecha    DATE NOT NULL
);

GO

/*
    4) Creación de tablas con referencias a las anteriores:
       - Articulo
       - Inventario
       - Cliente
       - Vendedor
       - Pedido
       - PedidoDetalle
       - Envio
       - Factura
       - FacturaDetalle
       - Pago
*/

/* TABLA: Articulo (representa la pieza de arte en venta) */
CREATE TABLE Articulo (
    ArticuloId           INT IDENTITY(1,1) PRIMARY KEY,
    CodigoArticulo       VARCHAR(50) NOT NULL,
    Titulo               VARCHAR(200) NOT NULL,
    Descripcion          VARCHAR(MAX) NOT NULL,
    ArtistaId            INT          NOT NULL,
    SubCategoriaArteId   INT          NOT NULL,
    PrecioBase           DECIMAL(18,2) NOT NULL,
    AñoCreacion          INT          NULL,
    CONSTRAINT CH_Articulo_PrecioNoNeg CHECK (PrecioBase >= 0),
    CONSTRAINT FK_Articulo_Artista 
        FOREIGN KEY (ArtistaId) REFERENCES Artista(ArtistaId),
    CONSTRAINT FK_Articulo_SubCategoriaArte 
        FOREIGN KEY (SubCategoriaArteId) REFERENCES SubCategoriaArte(SubCategoriaArteId),
    CONSTRAINT UQ_Articulo_CodigoArticulo UNIQUE (CodigoArticulo)
);

/* TABLA: Inventario */
CREATE TABLE Inventario (
    InventarioId INT IDENTITY(1,1) PRIMARY KEY,
    ArticuloId   INT NOT NULL,
    Cantidad     INT NOT NULL,
    Ubicacion    VARCHAR(200) NOT NULL,
    CONSTRAINT CH_Inventario_CantidadNoNeg CHECK (Cantidad >= 0),
    CONSTRAINT FK_Inventario_Articulo 
        FOREIGN KEY (ArticuloId) REFERENCES Articulo(ArticuloId)
);

/* TABLA: Cliente */
CREATE TABLE Cliente (
    ClienteId       INT IDENTITY(1,1) PRIMARY KEY,
    TipoDocumento   VARCHAR(10) NOT NULL,
    NumeroDocumento VARCHAR(20) NOT NULL,
    Nombre          VARCHAR(50) NOT NULL,
    Apellido        VARCHAR(50) NOT NULL,
    DireccionId     INT         NOT NULL,
    FechaRegistro   INT         NOT NULL, 
    CONSTRAINT CH_Cliente_NombreNoDigitos CHECK (Nombre NOT LIKE '%[0-9]%'),
    CONSTRAINT CH_Cliente_ApellidoNoDigitos CHECK (Apellido NOT LIKE '%[0-9]%'),
    CONSTRAINT FK_Cliente_Direccion 
        FOREIGN KEY (DireccionId) REFERENCES Direccion(DireccionId),
    CONSTRAINT FK_Cliente_Fecha 
        FOREIGN KEY (FechaRegistro) REFERENCES Fecha(FechaId),
    CONSTRAINT UQ_Cliente_TipoNumDoc UNIQUE (TipoDocumento, NumeroDocumento)
);

/* TABLA: Vendedor */
CREATE TABLE Vendedor (
    VendedorId      INT IDENTITY(1,1) PRIMARY KEY,
    TipoDocumento   VARCHAR(10) NOT NULL,
    NumeroDocumento VARCHAR(20) NOT NULL,
    Nombre          VARCHAR(50) NOT NULL,
    Apellido        VARCHAR(50) NOT NULL,
    DireccionId     INT         NOT NULL,
    FechaRegistro   INT         NOT NULL,
    CONSTRAINT CH_Vendedor_NombreNoDigitos CHECK (Nombre NOT LIKE '%[0-9]%'),
    CONSTRAINT CH_Vendedor_ApellidoNoDigitos CHECK (Apellido NOT LIKE '%[0-9]%'),
    CONSTRAINT FK_Vendedor_Direccion 
        FOREIGN KEY (DireccionId) REFERENCES Direccion(DireccionId),
    CONSTRAINT FK_Vendedor_Fecha 
        FOREIGN KEY (FechaRegistro) REFERENCES Fecha(FechaId),
    CONSTRAINT UQ_Vendedor_TipoNumDoc UNIQUE (TipoDocumento, NumeroDocumento)
);

/* TABLA: Pedido (representa la orden de compra) */
CREATE TABLE Pedido (
    PedidoId      INT IDENTITY(1,1) PRIMARY KEY,
    NumeroPedido  INT NOT NULL,
    ClienteId     INT NOT NULL,
    VendedorId    INT NOT NULL,
    FechaId       INT NOT NULL,
    MetodoEnvioId INT NOT NULL,
    CONSTRAINT FK_Pedido_Cliente 
        FOREIGN KEY (ClienteId) REFERENCES Cliente(ClienteId),
    CONSTRAINT FK_Pedido_Vendedor 
        FOREIGN KEY (VendedorId) REFERENCES Vendedor(VendedorId),
    CONSTRAINT FK_Pedido_Fecha 
        FOREIGN KEY (FechaId) REFERENCES Fecha(FechaId),
    CONSTRAINT FK_Pedido_MetodoEnvio
        FOREIGN KEY (MetodoEnvioId) REFERENCES MetodoEnvio(MetodoEnvioId)
);

/* TABLA: PedidoDetalle (detalle de la orden) */
CREATE TABLE PedidoDetalle (
    PedidoDetalleId INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId        INT NOT NULL,
    ArticuloId      INT NOT NULL,
    Cantidad        INT NOT NULL,
    PrecioUnitario  DECIMAL(18,2) NOT NULL,
    CONSTRAINT CH_PedidoDetalle_CantidadPositiva CHECK (Cantidad > 0),
    CONSTRAINT CH_PedidoDetalle_PrecioPositivo   CHECK (PrecioUnitario >= 0),
    CONSTRAINT FK_PedidoDetalle_Pedido
        FOREIGN KEY (PedidoId) REFERENCES Pedido(PedidoId),
    CONSTRAINT FK_PedidoDetalle_Articulo
        FOREIGN KEY (ArticuloId) REFERENCES Articulo(ArticuloId)
);

/* TABLA: Envio (datos concretos de envío asociados a un Pedido) */
CREATE TABLE Envio (
    EnvioId       INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId      INT NOT NULL,
    DireccionId   INT NOT NULL,
    FechaEnvio    INT NULL,
    EstadoEnvio   VARCHAR(50) NOT NULL, /* 'Pendiente', 'Enviado', 'Entregado', etc. */
    CONSTRAINT FK_Envio_Pedido 
        FOREIGN KEY (PedidoId) REFERENCES Pedido(PedidoId),
    CONSTRAINT FK_Envio_Direccion
        FOREIGN KEY (DireccionId) REFERENCES Direccion(DireccionId),
    CONSTRAINT FK_Envio_FechaEnvio
        FOREIGN KEY (FechaEnvio) REFERENCES Fecha(FechaId)
);

/* TABLA: Factura (documento contable asociado a un Pedido) */
CREATE TABLE Factura (
    FacturaId     INT IDENTITY(1,1) PRIMARY KEY,
    PedidoId      INT NOT NULL,
    NroFactura    INT NOT NULL,
    FechaId       INT NOT NULL,
    CONSTRAINT FK_Factura_Pedido
        FOREIGN KEY (PedidoId) REFERENCES Pedido(PedidoId),
    CONSTRAINT FK_Factura_Fecha
        FOREIGN KEY (FechaId) REFERENCES Fecha(FechaId)
);

/* TABLA: FacturaDetalle (detalle contable) */
CREATE TABLE FacturaDetalle (
    FacturaDetalleId INT IDENTITY(1,1) PRIMARY KEY,
    FacturaId        INT NOT NULL,
    Concepto         VARCHAR(200) NOT NULL, 
    Importe          DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_FacturaDetalle_Factura
        FOREIGN KEY (FacturaId) REFERENCES Factura(FacturaId)
);

/* TABLA: Pago (registra el pago efectivo) */
CREATE TABLE Pago (
    PagoId        INT IDENTITY(1,1) PRIMARY KEY,
    FacturaId     INT NOT NULL,
    MetodoPagoId  INT NOT NULL,
    FechaId       INT NOT NULL,
    ImportePagado DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_Pago_Factura
        FOREIGN KEY (FacturaId) REFERENCES Factura(FacturaId),
    CONSTRAINT FK_Pago_MetodoPago
        FOREIGN KEY (MetodoPagoId) REFERENCES MetodoPago(MetodoPagoId),
    CONSTRAINT FK_Pago_Fecha
        FOREIGN KEY (FechaId) REFERENCES Fecha(FechaId)
);

GO

/*
    5) Insertar datos iniciales en las tablas que no tienen dependencias. 
*/

/* --------- TABLA: Pais --------- */
INSERT INTO Pais (Nombre, Continente)
VALUES ('España',          'Europa'),
       ('Argentina',       'América'),
       ('Estados Unidos',  'América'),
       ('Francia',         'Europa'),
       ('Italia',          'Europa'),
       ('Japón',           'Asia');

/* --------- TABLA: Region --------- */
INSERT INTO Region (Nombre, PaisId)
VALUES ('Cataluña',       1),
       ('Madrid',         1),
       ('Buenos Aires',   2),
       ('California',     3),
       ('Île-de-France',  4),
       ('Toscana',        5),
       ('Tokio',          6);

/* --------- TABLA: Ciudad --------- */
INSERT INTO Ciudad (Nombre, RegionId)
VALUES ('Barcelona',     1),
       ('Madrid',        2),
       ('Mar del Plata', 3),
       ('Los Angeles',   4),
       ('París',         5),
       ('Florencia',     6),
       ('Tokio City',    7),
       ('Sacramento',    4),
       ('Carapachay',    3);

/* --------- TABLA: Direccion --------- */
INSERT INTO Direccion (Calle, Numero, CodigoPostal, CiudadId)
VALUES ('Carrer de Mallorca', '123', '08036', 1),
       ('Av. Independencia',  '450', '7600',  3),
       ('Sunset Blvd',        '100', '90028', 4),
       ('Rue de Rivoli',      '77',  '75004', 5),
       ('Gran Vía',           '800', '28013', 2),
       ('Borgo',              '12',  '50125', 6),
       ('Avenida Fuji',       '999', '100-0001', 7),
       ('Pensilvania Ave',    '1600','95814', 8),
       ('Mitre',              '600', '7601',  3);

/* --------- TABLA: CategoriaArte --------- */
INSERT INTO CategoriaArte (NombreCategoria)
VALUES ('Pintura'),
       ('Escultura'),
       ('Fotografía'),
       ('Grabado'),
       ('Dibujo'),
       ('Cerámica');

/* --------- TABLA: SubCategoriaArte --------- */
INSERT INTO SubCategoriaArte (NombreSubCategoria, CategoriaArteId)
VALUES ('Óleo',       1),
       ('Acrílico',   1),
       ('Bronce',     2),
       ('Mármol',     2),
       ('Paisaje',    3),
       ('Retrato',    3),
       ('Litografía', 4),
       ('Carboncillo',5),
       ('Barro',      6),
       ('Gres',       6);

/* --------- TABLA: Artista --------- */
INSERT INTO Artista (Nombre, Apellido, Nacionalidad)
VALUES ('Pablo',     'Picasso',      'Española'),
       ('Auguste',   'Rodin',        'Francesa'),
       ('Frida',     'Kahlo',        'Mexicana'),
       ('Andy',      'Warhol',       'Estadounidense'),
       ('Leonardo',  'da Vinci',     'Italiana'),
       ('Katsushika','Hokusai',      'Japonesa'),
       ('Marc',      'Chagall',      'Bielorrusa'),
       ('El',        'Greco',        'Griega');

/* --------- TABLA: MetodoPago --------- */
INSERT INTO MetodoPago (Descripcion)
VALUES ('Tarjeta Crédito'),
       ('PayPal'),
       ('Transferencia Bancaria'),
       ('Criptomoneda');

/* --------- TABLA: MetodoEnvio --------- */
INSERT INTO MetodoEnvio (Descripcion, TiempoEstimado)
VALUES ('Envío Internacional', '7-15 días'),
       ('Envío Nacional',      '2-5 días'),
       ('Recogida en Tienda',  'Inmediato'),
       ('Mensajería Express',  '1-2 días');

/* --------- TABLA: Fecha --------- */
INSERT INTO Fecha (Fecha)
VALUES ('2023-01-01'),
       ('2023-01-02'),
       ('2023-02-10'),
       ('2023-03-15'),
       ('2023-04-10'),
       ('2023-04-11'),
       ('2023-05-01'),
       ('2023-05-20');

/* --------- TABLA: Inventario (cada fila corresponde a un ArticuloId ya existente) --------- */
INSERT INTO Articulo (CodigoArticulo, Titulo, Descripcion, ArtistaId, SubCategoriaArteId, PrecioBase, AñoCreacion)
VALUES ('ART001', 'Las Meninas',     'Óleo sobre lienzo',           1, 1, 1500.00, 1656),
       ('ART002', 'El Pensador',    'Escultura en bronce',         2, 3, 5000.00, 1902),
       ('ART003', 'La Columna',     'Fotografía en Paisaje',       3, 5, 600.00,  1932),
       ('ART004', 'Banana',         'Serigrafía pop art',          4, 7, 2000.00, 1966),
       ('ART005', 'Mona Lisa',      'Obra maestra del Renacimiento',5,1, 1000000.00,1503),
       ('ART006', 'La Gran Ola',    'Xilografía japonesa',         6, 4, 1200.00,  1830);

INSERT INTO Inventario (ArticuloId, Cantidad, Ubicacion)
VALUES (1,  2, 'Almacén Principal'),
       (2,  1, 'Sala de Exhibición'),
       (3,  5, 'Almacén Secundario'),
       (4,  2, 'Depósito Pop Art'),
       (5,  1, 'Galería Privada'),
       (6,  3, 'Almacén Principal');

/* --------- TABLA: Cliente --------- */
INSERT INTO Cliente (TipoDocumento, NumeroDocumento, Nombre, Apellido, DireccionId, FechaRegistro)
VALUES ('DNI', '12345678', 'Juan',   'Pérez',      1, 1),
       ('DNI', '23456789', 'María',  'García',     2, 2),
       ('DNI', '34567890', 'Carlos', 'López',      3, 3),
       ('PAS', 'ABC12345', 'Lucía',  'Martínez',   4, 4),
       ('DNI', '45678901', 'Ana',    'Núñez',      5, 5),
       ('DNI', '56789012', 'Miguel', 'Romero',     6, 6);

/* --------- TABLA: Vendedor --------- */
INSERT INTO Vendedor (TipoDocumento, NumeroDocumento, Nombre, Apellido, DireccionId, FechaRegistro)
VALUES ('DNI', '11111111', 'Pedro',   'Ramirez',   3, 3),
       ('DNI', '22222222', 'Liliana', 'Fernández', 2, 4),
       ('DNI', '33333333', 'José',    'Martínez',  1, 1),
       ('PAS', 'XYZ98765', 'Rosa',    'Fresno',    4, 5);

/* --------- TABLA: Pedido --------- */
INSERT INTO Pedido (NumeroPedido, ClienteId, VendedorId, FechaId, MetodoEnvioId)
VALUES (1001, 1, 1, 1, 1),
       (1002, 2, 2, 2, 2),
       (1003, 3, 1, 3, 4),
       (1004, 6, 4, 5, 3),
       (1005, 5, 3, 6, 1),
       (1006, 2, 4, 7, 2),
       (1007, 4, 1, 8, 1);

/* --------- TABLA: PedidoDetalle --------- */
INSERT INTO PedidoDetalle (PedidoId, ArticuloId, Cantidad, PrecioUnitario)
VALUES (1, 1, 1, 1500.00),
       (2, 2, 1, 5000.00),
       (2, 3, 2, 600.00),
       (3, 4, 1, 2000.00),
       (4, 5, 1, 1000000.00),
       (5, 6, 1, 1200.00),
       (6, 1, 1, 1500.00),
       (7, 2, 1, 5000.00);

/* --------- TABLA: Envio --------- */
INSERT INTO Envio (PedidoId, DireccionId, FechaEnvio, EstadoEnvio)
VALUES (1, 1, 2, 'Pendiente'),
       (2, 2, 3, 'Enviado'),
       (3, 3, 4, 'Entregado'),
       (4, 7, 5, 'Pendiente'),
       (5, 8, NULL, 'Pendiente'),
       (6, 9, 6, 'Enviado');

/* --------- TABLA: Factura --------- */
INSERT INTO Factura (PedidoId, NroFactura, FechaId)
VALUES (1, 2001, 2),
       (2, 2002, 3),
       (3, 2003, 4),
       (4, 2004, 5);

/* --------- TABLA: FacturaDetalle --------- */
INSERT INTO FacturaDetalle (FacturaId, Concepto, Importe)
VALUES (1, 'Compra Obra Arte - Las Meninas',   1500.00),
       (1, 'IVA 21%',                          315.00),
       (2, 'Compra Escultura - El Pensador',   5000.00),
       (2, 'Compra Fotografía - La Columna',   1200.00),
       (3, 'Compra Pop Art - Banana',          2000.00),
       (3, 'Impuesto Serv.',                   200.00),
       (4, 'Compra Obra - Mona Lisa',          1000000.00);

/* --------- TABLA: Pago --------- */
INSERT INTO Pago (FacturaId, MetodoPagoId, FechaId, ImportePagado)
VALUES (1, 1, 3, 1815.00),
       (2, 2, 4, 6200.00),
       (3, 2, 6, 2200.00),
       (4, 4, 7, 1000000.00);

GO

/*
    6) Crear una vista general que relacione las entidades principales
       (Pedido, PedidoDetalle, Cliente, Vendedor, Articulo, Factura, Pago, etc.)
*/
CREATE VIEW vw_ArteGeneral AS
SELECT 
    p.PedidoId,
    p.NumeroPedido,
    c.ClienteId,
    c.TipoDocumento AS ClienteTipoDoc,
    c.NumeroDocumento AS ClienteNroDoc,
    c.Nombre AS ClienteNombre,
    c.Apellido AS ClienteApellido,
    v.VendedorId,
    v.TipoDocumento AS VendedorTipoDoc,
    v.NumeroDocumento AS VendedorNroDoc,
    v.Nombre AS VendedorNombre,
    v.Apellido AS VendedorApellido,
    pd.PedidoDetalleId,
    pd.ArticuloId,
    a.Titulo AS ArticuloTitulo,
    a.Descripcion AS ArticuloDescripcion,
    pd.Cantidad,
    pd.PrecioUnitario,
    f.FacturaId,
    f.NroFactura,
    pg.PagoId,
    pg.ImportePagado,
    mp.Descripcion AS MetodoPago,
    me.Descripcion AS MetodoEnvio,
    en.EnvioId,
    en.EstadoEnvio
FROM Pedido p
INNER JOIN PedidoDetalle pd 
    ON p.PedidoId = pd.PedidoId
INNER JOIN Articulo a
    ON pd.ArticuloId = a.ArticuloId
INNER JOIN Cliente c
    ON p.ClienteId = c.ClienteId
INNER JOIN Vendedor v
    ON p.VendedorId = v.VendedorId
LEFT JOIN Factura f
    ON p.PedidoId = f.PedidoId
LEFT JOIN Pago pg
    ON f.FacturaId = pg.FacturaId
LEFT JOIN MetodoPago mp
    ON pg.MetodoPagoId = mp.MetodoPagoId
LEFT JOIN MetodoEnvio me
    ON p.MetodoEnvioId = me.MetodoEnvioId
LEFT JOIN Envio en
    ON p.PedidoId = en.PedidoId;
GO

/*
    7) Consulta de ejemplo a la vista
*/
SELECT * 
FROM vw_ArteGeneral;
GO
