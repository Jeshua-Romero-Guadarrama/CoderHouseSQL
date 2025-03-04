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


/* ----------------------------------------------------------------------------
   VISTAS
-------------------------------------------------------------------------------
1) vw_ResumenClientes
   - Descripción: Muestra un resumen de clientes, total de pedidos, y último pedido realizado.
   - Objetivo: Conocer cuántas órdenes ha hecho cada cliente y la fecha más reciente.
   - Tablas involucradas: Cliente, Pedido, Fecha.

2) vw_StockArticulos
   - Descripción: Combina Articulo e Inventario para mostrar stock disponible y precio base.
   - Objetivo: Ver rápidamente la cantidad disponible de cada artículo y su precio.
   - Tablas involucradas: Articulo, Inventario.
---------------------------------------------------------------------------- */

/* 1) Vista: vw_ResumenClientes */
CREATE OR REPLACE VIEW vw_ResumenClientes AS
SELECT 
    c.ClienteId,
    CONCAT(c.Nombre, ' ', c.Apellido) AS NombreCompleto,
    COUNT(p.PedidoId) AS TotalPedidos,
    MAX(f.Fecha) AS UltimaFechaPedido
FROM Cliente c
LEFT JOIN Pedido p 
    ON c.ClienteId = p.ClienteId
LEFT JOIN Fecha f
    ON p.FechaId = f.FechaId
GROUP BY c.ClienteId, NombreCompleto;


/* 2) Vista: vw_StockArticulos */
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
   FUNCIONES
-------------------------------------------------------------------------------
1) FN_CalcularIVA
    - Descripción: Dada una cantidad monetaria, calcula el IVA al 21%.
    - Objetivo: Se puede utilizar para mostrar en reportes o calcular totales con IVA.
    - Tablas manipuladas: No manipula tablas; es meramente cálculo.
---------------------------------------------------------------------------- */

/* 1) Función: FN_CalcularIVA */
DELIMITER $$
CREATE FUNCTION FN_CalcularIVA(
    p_base DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_resultado DECIMAL(10,2);
    SET v_resultado = p_base * 0.21;  /* IVA del 21% */
    RETURN v_resultado;
END $$
DELIMITER ;

/* ----------------------------------------------------------------------------
   STORED PROCEDURES
-------------------------------------------------------------------------------
1) SP_ActualizarStock
    - Descripción: Recibe el ID del artículo y la cantidad vendida; descuenta del Inventario.
    - Objetivo: Automatizar la actualización del stock cada vez que se concreta una venta.
    - Tablas involucradas: Inventario
---------------------------------------------------------------------------- */

/* 1) Stored Procedure: SP_ActualizarStock */
DELIMITER $$
CREATE PROCEDURE SP_ActualizarStock(
    IN p_ArticuloId INT,
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
    TRIGGERS
-------------------------------------------------------------------------------
1) TR_RestarStockDespuesPedido
    - Descripción: Al insertar un PedidoDetalle, descuenta automáticamente stock del Inventario.
    - Objetivo: Mantener sincronizada la tabla Inventario sin necesidad de llamados manuales.
    - Tablas involucradas: PedidoDetalle (evento), e Inventario (afectada a través del SP).
---------------------------------------------------------------------------- */

/* 1) Trigger: TR_RestarStockDespuesPedido */
DELIMITER $$
CREATE TRIGGER TR_RestarStockDespuesPedido
AFTER INSERT
ON PedidoDetalle
FOR EACH ROW
BEGIN
    CALL SP_ActualizarStock(NEW.ArticuloId, NEW.Cantidad);
END $$
DELIMITER ;

/* FIN DEL SCRIPT DBArte_objetos_avanzados.sql */