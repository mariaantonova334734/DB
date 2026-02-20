USE BankCashOrder2;
GO

-- ПРЕДСТАВЛЕНИЕ: отчет по каждому отделению с разбивкой по статусам

CREATE VIEW Отчет_Доставка_ТекущийМесяц_Детальный AS
SELECT 
    o.отделение_id,
    o.код_отделения,
    o.название AS отделение,
    o.город,
    o.регион,
    -- Текущий месяц (автоматически определяет текущий месяц и год)
    YEAR(GETDATE()) AS год,
    MONTH(GETDATE()) AS месяц,
    -- Статистика по заказам в текущем месяце
    COUNT(DISTINCT z.заказ_id) AS количество_заказов_всего,
    COUNT(DISTINCT CASE WHEN z.статус_Заказа = 'Выдан' THEN z.заказ_id END) AS количество_выданных,
    COUNT(DISTINCT CASE WHEN z.статус_Заказа = 'Готов к выдаче' THEN z.заказ_id END) AS количество_готовых,
    COUNT(DISTINCT CASE WHEN z.статус_Заказа = 'Отменен' THEN z.заказ_id END) AS количество_отмененных,
    -- Суммы по заказам
    ISNULL(SUM(CASE WHEN z.статус_Заказа = 'Выдан' THEN z.сумма ELSE 0 END), 0) AS сумма_выданных,
    ISNULL(SUM(CASE WHEN z.статус_Заказа = 'Готов к выдаче' THEN z.сумма ELSE 0 END), 0) AS сумма_готовых,
    ISNULL(SUM(CASE WHEN z.статус_Заказа = 'Отменен' THEN z.сумма ELSE 0 END), 0) AS сумма_отмененных,
    ISNULL(SUM(z.сумма), 0) AS сумма_всего,
    -- Комиссии
    ISNULL(SUM(z.комиссия), 0) AS общая_комиссия,
    -- Средний чек
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN z.статус_Заказа = 'Выдан' THEN z.заказ_id END) > 0 
        THEN ISNULL(SUM(CASE WHEN z.статус_Заказа = 'Выдан' THEN z.сумма ELSE 0 END) / 
                   COUNT(DISTINCT CASE WHEN z.статус_Заказа = 'Выдан' THEN z.заказ_id END), 0)
        ELSE 0
    END AS средний_чек,
    -- Информация о доставках
    COUNT(DISTINCT d.доставка_id) AS количество_доставок,
    COUNT(DISTINCT CASE WHEN d.статус = 'доставлено' THEN d.доставка_id END) AS доставок_выполнено,
    -- Количество сотрудников в отделении
    COUNT(DISTINCT s.сотрудник_id) AS количество_сотрудников
FROM 
    ОтделениеБанка o
    LEFT JOIN ЗаказНаличных z ON o.отделение_id = z.отделение_id 
        AND MONTH(z.дата_запроса) = MONTH(GETDATE())
        AND YEAR(z.дата_запроса) = YEAR(GETDATE())
    LEFT JOIN ДоставкаНаличных d ON z.заказ_id = d.заказ_id
    LEFT JOIN Сотрудник s ON o.отделение_id = s.отделение_id AND s.статус = 'активен'
GROUP BY 
    o.отделение_id, o.код_отделения, o.название, o.город, o.регион;
GO

