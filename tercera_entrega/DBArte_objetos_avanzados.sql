/*
-------------------------------------------------------------------------------------------
Archivo: 
DBArte_objetos_avanzados.sql
Descripción:
- Script que crea vistas adicionales.
- Script que crea funciones.
- Script que crea stored procedures.
- Script que crea triggers. 
-------------------------------------------------------------------------------------------
*/

/* ============================================================================
   VISTAS (6 en total)
============================================================================ */

/* ----------------------------------------------------------------------------
1) vw_ResumenClientes
   - Descripción: Muestra un resumen de clientes, la cantidad total de pedidos realizados
                  y la fecha del pedido más reciente.
   - Objetivo: Conocer cuántas órdenes ha hecho cada cliente y la fecha más reciente,
               para analizar su frecuencia de compra.
   - Tablas manipuladas: Cliente, Pedido, Fecha.
---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_ResumenClientes AS
SELECT
        c.ClienteId,
        CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCompleto,
        COUNT(p.PedidoId)                 AS TotalPedidos,
        MAX(f.Fecha)                      AS UltimaFechaPedido
  FROM Cliente c
  LEFT JOIN Pedido p 
    ON c.ClienteId = p.ClienteId
  LEFT JOIN Fecha f
    ON p.FechaId = f.FechaId
 GROUP BY c.ClienteId, NombreCompleto;

/* ----------------------------------------------------------------------------
2) vw_StockArticulos
   - Descripción: Combina la tabla Articulo con Inventario para mostrar la cantidad
                  disponible (stock) de cada artículo, así como su ubicación y precio base.
   - Objetivo: Visualizar rápidamente el stock disponible y el precio base de cada artículo,
               facilitando la gestión de inventario.
   - Tablas manipuladas: Articulo, Inventario.
---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_StockArticulos AS
SELECT 
        a.ArticuloId,
        a.CodigoArticulo,
        a.Titulo,
        a.PrecioBase,
        i.Cantidad AS StockDisponible,
        i.Ubicacion
  FROM Articulo a
 INNER JOIN Inventario i
    ON a.ArticuloId = i.ArticuloId;

/* ----------------------------------------------------------------------------
3) vw_ArteGeneral
   - Descripción: Combina la información principal de pedidos, detalles de pedido,
                  clientes, vendedores, artículos, facturas, pagos y envíos en una
                  única vista general.
   - Objetivo: Obtener un panorama unificado de las ventas, mostrando por cada pedido
               quién es el cliente, cuál es el artículo, cuál es el método de envío y
               pago, si existe factura y si se realizó el pago, etc.
   - Tablas manipuladas: Pedido, PedidoDetalle, Articulo, Cliente, Vendedor, Factura, 
                          Pago, MetodoPago, MetodoEnvio, Envio.
---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_ArteGeneral AS
SELECT 
        p.PedidoId,
        p.NumeroPedido,
        c.ClienteId,
        c.TipoDocumento   AS ClienteTipoDoc,
        c.NumeroDocumento AS ClienteNroDoc,
        c.Nombre          AS ClienteNombre,
        c.Apellido        AS ClienteApellido,
        v.VendedorId,
        v.TipoDocumento   AS VendedorTipoDoc,
        v.NumeroDocumento AS VendedorNroDoc,
        v.Nombre          AS VendedorNombre,
        v.Apellido        AS VendedorApellido,
        pd.PedidoDetalleId,
        pd.ArticuloId,
        a.Titulo          AS ArticuloTitulo,
        a.Descripcion     AS ArticuloDescripcion,
        pd.Cantidad,
        pd.PrecioUnitario,
        f.FacturaId,
        f.NroFactura,
        pg.PagoId,
        pg.ImportePagado,
        mp.Descripcion    AS MetodoPago,
        me.Descripcion    AS MetodoEnvio,
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

/* ----------------------------------------------------------------------------
4) vw_VentasPorMes
   - Descripción: Muestra cuántos pedidos se han realizado por mes (YYYY-MM) y el total
                  facturado en ese período.
   - Objetivo: Ayudar a entender la evolución de las ventas a lo largo de los meses,
               permitiendo identificar picos y planificar estrategias de venta.
   - Tablas manipuladas: Pedido, PedidoDetalle, Fecha.
---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_VentasPorMes AS
SELECT
        DATE_FORMAT(f.Fecha, '%Y-%m')        AS AnioMes,
        COUNT(DISTINCT p.PedidoId)           AS TotalPedidos,
        SUM(pd.Cantidad * pd.PrecioUnitario) AS MontoVendido
  FROM Pedido p
 INNER JOIN PedidoDetalle pd 
    ON p.PedidoId = pd.PedidoId
 INNER JOIN Fecha f
    ON p.FechaId = f.FechaId
 GROUP BY DATE_FORMAT(f.Fecha, '%Y-%m');

/* ----------------------------------------------------------------------------
5) vw_TopArtistas
   - Descripción: Lista a los artistas con la suma total de ventas en la que participan
                  sus artículos.
   - Objetivo: Identificar los artistas cuyas obras generan mayores ingresos, ayudando
               a decidir dónde enfocar esfuerzos de promoción y/o adquisiciones.
   - Tablas manipuladas: PedidoDetalle, Articulo, Artista, Pedido.
---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_TopArtistas AS
SELECT 
        ar.ArtistaId,
        CONCAT(ar.Nombre, ' ', ar.Apellido)  AS ArtistaNombre,
        SUM(pd.Cantidad * pd.PrecioUnitario) AS TotalVentas
  FROM PedidoDetalle pd
 INNER JOIN Articulo a
    ON pd.ArticuloId = a.ArticuloId
 INNER JOIN Artista ar
    ON a.ArtistaId = ar.ArtistaId
 INNER JOIN Pedido p
    ON pd.PedidoId = p.PedidoId
 GROUP BY ar.ArtistaId, CONCAT(ar.Nombre, ' ', ar.Apellido)
 ORDER BY TotalVentas DESC;

/* ----------------------------------------------------------------------------
6) vw_ClientesPorRegion
   - Descripción: Muestra cuántos clientes hay por región y país, junto al último pedido
                  que realizaron (si existe).
   - Objetivo: Conocer la concentración geográfica de los clientes y su actividad,
               permitiendo definir estrategias de marketing por región.
   - Tablas manipuladas: Cliente, Direccion, Ciudad, Region, Pais, Pedido.
---------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_ClientesPorRegion AS
SELECT 
        r.Nombre                          AS Region,
        pa.Nombre                         AS Pais,
        c.ClienteId,
        CONCAT(c.Nombre, ' ', c.Apellido) AS Cliente,
        MAX(p.PedidoId)                   AS UltimoPedidoId
  FROM Cliente c
 INNER JOIN Direccion d
    ON c.DireccionId = d.DireccionId
 INNER JOIN Ciudad ci
    ON d.CiudadId = ci.CiudadId
 INNER JOIN Region r
    ON ci.RegionId = r.RegionId
 INNER JOIN Pais pa
    ON r.PaisId = pa.PaisId
 LEFT JOIN Pedido p
    ON p.ClienteId = c.ClienteId
 GROUP BY r.Nombre, pa.Nombre, c.ClienteId, Cliente;

/* ============================================================================
   FUNCIONES (6 en total)
============================================================================ */

/* ----------------------------------------------------------------------------
1) FN_CalcularIVA
   - Descripción: Dada una cantidad monetaria, calcula el IVA al 21%.
   - Objetivo: Se puede utilizar para mostrar en reportes o calcular totales con IVA.
   - Tablas manipuladas: No manipula tablas; es un cálculo aritmético puro.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE FUNCTION FN_CalcularIVA(
    p_base DECIMAL(10, 2)
)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
        DECLARE v_resultado DECIMAL(10, 2);
        SET v_resultado = p_base * 0.21;  /* IVA del 21% */
        RETURN v_resultado;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
2) FN_CalcularPrecioConIVA
   - Descripción: Retorna el precio base más el IVA (21%), llamando internamente a FN_CalcularIVA.
   - Objetivo: Obtener el monto final con impuestos incluidos, útil en listados o facturación.
   - Tablas manipuladas: Ninguna (solo usa FN_CalcularIVA).
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE FUNCTION FN_CalcularPrecioConIVA(
    p_base DECIMAL(10, 2)
)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
        RETURN p_base + FN_CalcularIVA(p_base);
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
3) FN_ObtenerCantidadPedidosCliente
   - Descripción: Devuelve la cantidad total de pedidos realizados por un cliente.
   - Objetivo: Identificar qué clientes compran más seguido, para acciones de fidelización.
   - Tablas manipuladas: Consulta la tabla Pedido.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE FUNCTION FN_ObtenerCantidadPedidosCliente(
    p_ClienteId INT
)
RETURNS INT
DETERMINISTIC
BEGIN
        DECLARE v_total INT;
         SELECT COUNT(*) INTO v_total
           FROM Pedido
          WHERE ClienteId = p_ClienteId;
         RETURN v_total;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
4) FN_ObtenerNombreCompletoArtista
   - Descripción: Dado el ID de un artista, concatena Nombre y Apellido.
   - Objetivo: Estandarizar la forma de mostrar el nombre completo del artista,
               útil en reportes.
   - Tablas manipuladas: Consulta la tabla Artista.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE FUNCTION FN_ObtenerNombreCompletoArtista(
    p_ArtistaId INT
)
RETURNS VARCHAR(200)
DETERMINISTIC
BEGIN
        DECLARE v_nombreCompleto VARCHAR(200);
         SELECT CONCAT(Nombre, ' ', Apellido)
           INTO v_nombreCompleto
           FROM Artista
          WHERE ArtistaId = p_ArtistaId;
         RETURN v_nombreCompleto;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
5) FN_CalcularEdadObra
   - Descripción: Calcula la antigüedad de una obra en años, restando el año actual
                  menos el año de creación.
   - Objetivo: Permitir reportes o filtros basados en cuán antigua es cada pieza.
   - Tablas manipuladas: Consulta la tabla Articulo.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE FUNCTION FN_CalcularEdadObra(
    p_ArticuloId INT
)
RETURNS INT
DETERMINISTIC
BEGIN
        DECLARE v_anoCreacion INT;
        DECLARE v_edad INT;
         SELECT AnoCreacion
           INTO v_anoCreacion
           FROM Articulo
          WHERE ArticuloId = p_ArticuloId;
             IF v_anoCreacion IS NULL THEN
                SET v_edad = 0; -- Obra sin año de creación definido
           ELSE
                SET v_edad = YEAR(CURDATE()) - v_anoCreacion;
            END IF;
         RETURN v_edad;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
6) FN_CalcularComisionVendedor
   - Descripción: Aplica una comisión (5%) al valor total de los pedidos gestionados
                  por un vendedor.
   - Objetivo: Automatizar o simplificar el cálculo de compensaciones al personal de ventas.
   - Tablas manipuladas: Consulta Pedido y PedidoDetalle.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE FUNCTION FN_CalcularComisionVendedor(
    p_VendedorId INT
)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
       DECLARE v_totalVentas DECIMAL(10, 2);
       DECLARE v_comision    DECIMAL(10, 2);
        SELECT IFNULL(SUM(pd.Cantidad * pd.PrecioUnitario), 0)
          INTO v_totalVentas
          FROM Pedido p
          JOIN PedidoDetalle pd 
            ON p.PedidoId = pd.PedidoId
         WHERE p.VendedorId = p_VendedorId;
           SET v_comision = v_totalVentas * 0.05; -- 5%
        RETURN v_comision;
END $$
DELIMITER ;

/* ============================================================================
   STORED PROCEDURES (6 en total)
============================================================================ */

/* ----------------------------------------------------------------------------
1) SP_ActualizarStock
   - Descripción: Recibe el ID del artículo y la cantidad vendida; descuenta esa
                  cantidad en la tabla Inventario.
   - Objetivo: Automatizar la actualización del stock cada vez que se concreta una venta.
   - Tablas manipuladas: Inventario.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE PROCEDURE SP_ActualizarStock(
    IN p_ArticuloId      INT,
    IN p_CantidadVendida INT
)
BEGIN
        UPDATE Inventario
           SET Cantidad = Cantidad - p_CantidadVendida
         WHERE ArticuloId = p_ArticuloId
           AND Cantidad >= p_CantidadVendida;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
2) SP_RegistrarCliente
   - Descripción: Inserta un nuevo registro en la tabla Cliente, recibiendo como
                  parámetros los datos básicos y la fecha de registro.
   - Objetivo: Estandarizar la alta de clientes para asegurar que se capten
               correctamente los datos y no falte información.
   - Tablas manipuladas: Cliente.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE PROCEDURE SP_RegistrarCliente(
    IN p_TipoDoc       VARCHAR(10),
    IN p_NumDoc        VARCHAR(20),
    IN p_Nombre        VARCHAR(50),
    IN p_Apellido      VARCHAR(50),
    IN p_DireccionId   INT,
    IN p_FechaRegistro INT
)
BEGIN
        INSERT INTO Cliente (TipoDocumento, NumeroDocumento, Nombre, Apellido, DireccionId, FechaRegistro)
        VALUES (p_TipoDoc, p_NumDoc, p_Nombre, p_Apellido, p_DireccionId, p_FechaRegistro);
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
3) SP_RegistrarPedidoCompleto
   - Descripción: Crea un pedido en la tabla Pedido y, a continuación, registra
                  los detalles (artículos, cantidades, precio unitario) a partir
                  de un JSON.
   - Objetivo: Simplificar la creación de pedidos con múltiples artículos en
               un solo proceso.
   - Tablas manipuladas: Pedido, PedidoDetalle.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE PROCEDURE SP_RegistrarPedidoCompleto(
    IN p_NumeroPedido  INT,
    IN p_ClienteId     INT,
    IN p_VendedorId    INT,
    IN p_FechaId       INT,
    IN p_MetodoEnvioId INT,
    IN p_Detalles      JSON
)
BEGIN
        DECLARE v_nuevoPedidoId INT;
        -- Inserta el pedido
         INSERT INTO Pedido (NumeroPedido, ClienteId, VendedorId, FechaId, MetodoEnvioId)
         VALUES (p_NumeroPedido, p_ClienteId, p_VendedorId, p_FechaId, p_MetodoEnvioId);
            SET v_nuevoPedidoId = LAST_INSERT_ID();
        /*
            Formato esperado en p_Detalles:
            [
                {"ArticuloId":1, "Cantidad":2, "PrecioUnitario":1500.00},
                {"ArticuloId":4, "Cantidad":1, "PrecioUnitario":2000.00}
            ]
            (Ajustar según versión de MySQL/MariaDB y manejo de JSON.)
        */
         INSERT INTO PedidoDetalle (PedidoId, ArticuloId, Cantidad, PrecioUnitario)
         SELECT 
                v_nuevoPedidoId,
                JSON_EXTRACT(j.value, '$.ArticuloId'),
                JSON_EXTRACT(j.value, '$.Cantidad'),
                JSON_EXTRACT(j.value, '$.PrecioUnitario')
           FROM JSON_TABLE(p_Detalles, '$[*]' COLUMNS (value JSON PATH '$')) AS j;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
4) SP_MarcarEnvioComoEntregado
   - Descripción: Cambia el estado de un envío a "Entregado" y actualiza la fecha
                  de envío con el valor recibido.
   - Objetivo: Simplificar la confirmación de entrega de un pedido, manteniendo
               consistencia con la tabla Envio.
   - Tablas manipuladas: Envio.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE PROCEDURE SP_MarcarEnvioComoEntregado(
    IN p_EnvioId    INT,
    IN p_FechaEnvio INT
)
BEGIN
        UPDATE Envio
           SET EstadoEnvio = 'Entregado',
               FechaEnvio  = p_FechaEnvio
         WHERE EnvioId = p_EnvioId;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
5) SP_ActualizarPrecioArticulo
   - Descripción: Modifica el precio base de un artículo, recibiendo el nuevo
                  valor como parámetro.
   - Objetivo: Permitir que el personal autorizado actualice los precios sin
               necesidad de editar manualmente la tabla.
   - Tablas manipuladas: Articulo.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE PROCEDURE SP_ActualizarPrecioArticulo(
    IN p_ArticuloId  INT,
    IN p_NuevoPrecio DECIMAL(18,2)
)
BEGIN
        UPDATE Articulo
           SET PrecioBase = p_NuevoPrecio
         WHERE ArticuloId = p_ArticuloId;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
6) SP_EliminarPedido
   - Descripción: Elimina un pedido junto con sus detalles y la factura asociada
                  (si existe).
   - Objetivo: Dar una manera controlada de anular o retirar pedidos completos,
               protegiendo la integridad referencial.
   - Tablas manipuladas: Pedido, PedidoDetalle, Factura.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE PROCEDURE SP_EliminarPedido(
    IN p_PedidoId INT
)
BEGIN
        DELETE FROM PedidoDetalle
         WHERE PedidoId = p_PedidoId;
        DELETE FROM Factura
         WHERE PedidoId = p_PedidoId;
        DELETE FROM Pedido
         WHERE PedidoId = p_PedidoId;
END $$
DELIMITER ;

/* ============================================================================
   TRIGGERS (6 en total)
============================================================================ */

/* ----------------------------------------------------------------------------
1) TR_RestarStockDespuesPedido
   - Descripción: Al insertar un nuevo registro en PedidoDetalle, descuenta
                  automáticamente la cantidad vendida del Inventario mediante
                  SP_ActualizarStock.
   - Objetivo: Mantener sincronizado el stock sin necesidad de que el usuario
               invoque manualmente la actualización de Inventario.
   - Tablas manipuladas: PedidoDetalle (evento), Inventario (afectada vía SP).
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE TRIGGER TR_RestarStockDespuesPedido
 AFTER INSERT
    ON PedidoDetalle
   FOR EACH ROW
BEGIN
        CALL SP_ActualizarStock(NEW.ArticuloId, NEW.Cantidad);
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
2) TR_ActualizarFechaEnvioEnEntregado
   - Descripción: Antes de actualizar un Envio, si el nuevo estado es "Entregado"
                  y FechaEnvio es NULL, se asigna la fecha actual (asumiendo que
                  existe en la tabla Fecha).
   - Objetivo: Evitar que se queden envíos marcados como entregados sin
               registrar la fecha real de entrega.
   - Tablas manipuladas: Envio (evento), Fecha (consulta).
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE TRIGGER TR_ActualizarFechaEnvioEnEntregado
BEFORE UPDATE
    ON Envio
   FOR EACH ROW
BEGIN
        IF NEW.EstadoEnvio = 'Entregado' AND NEW.FechaEnvio IS NULL THEN
            SET NEW.FechaEnvio = (
                                  SELECT FechaId 
                                    FROM Fecha 
                                   WHERE Fecha = CURDATE() 
                                   LIMIT 1
                                 );
        END IF;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
3) TR_ValidarFechaFactura
   - Descripción: Antes de insertar una Factura, valida que su fecha no sea
                  anterior a la fecha del pedido correspondiente.
   - Objetivo: Prevenir inconsistencias temporales (ej. facturar antes de que
               exista el pedido).
   - Tablas manipuladas: Factura (evento), Pedido, Fecha.
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE TRIGGER TR_ValidarFechaFactura
BEFORE INSERT
    ON Factura
   FOR EACH ROW
BEGIN
        DECLARE v_fechaPedido DATE;
        DECLARE v_fechaFactura DATE;
         SELECT f.Fecha INTO v_fechaPedido
           FROM Pedido p
           JOIN Fecha f 
             ON p.FechaId = f.FechaId
          WHERE p.PedidoId = NEW.PedidoId;
         SELECT f2.Fecha INTO v_fechaFactura
           FROM Fecha f2
          WHERE f2.FechaId = NEW.FechaId;
        IF v_fechaFactura < v_fechaPedido THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'La fecha de la factura no puede ser anterior a la del pedido.';
        END IF;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
4) TR_LogEliminacionCliente
   - Descripción: Después de eliminar un cliente, registra el suceso en una
                  tabla de auditoría "LogEliminacionCliente" con la fecha-hora
                  y un motivo.
   - Objetivo: Mantener trazabilidad y registro histórico de la eliminación
               de clientes para fines administrativos o de auditoría.
   - Tablas manipuladas: Cliente (evento), LogEliminacionCliente (inserción).
---------------------------------------------------------------------------- */
/* Crear tabla de log si no existe */
CREATE TABLE IF NOT EXISTS LogEliminacionCliente (
    LogId      INT          AUTO_INCREMENT PRIMARY KEY,
    ClienteId  INT          NOT NULL,
    FechaHora  DATETIME     NOT NULL,
    Motivo     VARCHAR(255) NULL
);

DELIMITER $$
CREATE TRIGGER TR_LogEliminacionCliente
 AFTER DELETE
    ON Cliente
   FOR EACH ROW
BEGIN
        INSERT INTO LogEliminacionCliente (ClienteId, FechaHora, Motivo)
        VALUES (OLD.ClienteId, NOW(), 'Eliminación del cliente');
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
5) TR_CalcularDetalleFactura
   - Descripción: Antes de insertar un detalle de factura, se pueden realizar
                  ajustes al importe. A modo de ejemplo, si el concepto no
                  incluye "IVA", podríamos añadirlo automáticamente.
   - Objetivo: Automatizar parte del cálculo de impuestos u otras tasas,
               evitando que el usuario deba hacerlo manualmente.
   - Tablas manipuladas: FacturaDetalle (evento).
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE TRIGGER TR_CalcularDetalleFactura
BEFORE INSERT
    ON FacturaDetalle
   FOR EACH ROW
BEGIN
        IF NEW.Concepto NOT LIKE '%IVA%' THEN
            SET NEW.Importe = NEW.Importe;
            -- SET NEW.Importe = NEW.Importe + FN_CalcularIVA(NEW.Importe);
        END IF;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
6) TR_CrearPagoAutomatico
   - Descripción: Al insertar una nueva Factura, se inserta automáticamente
                  un registro en Pago, calculando el total de la factura y
                  usando un método de pago por defecto (por ejemplo, 1 => Tarjeta).
   - Objetivo: Ilustrar la automatización de pagos. En un entorno real, se
               verificarían condiciones adicionales, pero sirve como ejemplo.
   - Tablas manipuladas: Factura (evento), FacturaDetalle (consulta), Pago (inserción).
---------------------------------------------------------------------------- */
DELIMITER $$
CREATE TRIGGER TR_CrearPagoAutomatico
 AFTER INSERT
    ON Factura
   FOR EACH ROW
BEGIN
        DECLARE v_importeTotal DECIMAL(18,2);
         SELECT IFNULL(SUM(Importe), 0)
           INTO v_importeTotal
           FROM FacturaDetalle
          WHERE FacturaId = NEW.FacturaId;
         INSERT INTO Pago (FacturaId, MetodoPagoId, FechaId, ImportePagado)
         VALUES (NEW.FacturaId, 1, NEW.FechaId, v_importeTotal);
END $$
DELIMITER ;

/*
-------------------------------------------------------------------------------------------
FIN DEL SCRIPT: DBArte_objetos_avanzados.sql
-------------------------------------------------------------------------------------------
*/