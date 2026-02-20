-- =====================================================
-- База данных: Система заказа наличных в отделении банка 
-- =====================================================

-- Создание базы данных
CREATE DATABASE BankCashOrder2;
GO

USE BankCashOrder2;
GO

-- =======================================================
-- Таблица: Клиент
-- =====================================================
CREATE TABLE Клиент (
    клиент_id INT IDENTITY(1,1) PRIMARY KEY,
    имя NVARCHAR(100) NOT NULL,
    фамилия NVARCHAR(100) NOT NULL,
    телефон NVARCHAR(20) NOT NULL,
    email NVARCHAR(255) NOT NULL,
    серия_паспорта NVARCHAR(10) NULL,
    номер_паспорта NVARCHAR(20) NULL,
    кем_выдан NVARCHAR(255) NULL,
    дата_регистрации DATE NOT NULL,
    статус NVARCHAR(20) NOT NULL CONSTRAINT CK_Клиент_статус CHECK (статус IN ('активен', 'заблокирован', 'удален')),
    дата_создания DATETIME2 NOT NULL DEFAULT GETDATE(),
    дата_обновления DATETIME2 NULL
);
GO

-- =====================================================
-- Таблица: ОтделениеБанка
-- ======================================================
CREATE TABLE ОтделениеБанка (
    отделение_id INT IDENTITY(1,1) PRIMARY KEY,
    код_отделения NVARCHAR(20) NOT NULL UNIQUE,
    название NVARCHAR(255) NOT NULL,
    адрес NVARCHAR(500) NOT NULL,
    телефон NVARCHAR(20) NULL,
    email NVARCHAR(255) NOT NULL,
    часы_работы NVARCHAR(100) NULL,
    город NVARCHAR(100) NOT NULL,
    регион NVARCHAR(100) NOT NULL,
    статус NVARCHAR(20) NOT NULL CONSTRAINT CK_Отделение_статус CHECK (статус IN ('активно', 'неактивно', 'временно_неактивно'))
);
GO


-- =====================================================
-- Таблица: Сотрудник
-- =====================================================
CREATE TABLE Сотрудник (
    сотрудник_id INT IDENTITY(1,1) PRIMARY KEY,
    отделение_id INT NOT NULL,
    имя NVARCHAR(100) NOT NULL,
    фамилия NVARCHAR(100) NOT NULL,
    должность NVARCHAR(100) NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    внутренний_телефон NVARCHAR(10) NULL,
    логин NVARCHAR(50) NOT NULL UNIQUE,
    роль NVARCHAR(30) NOT NULL,
    статус NVARCHAR(20) NOT NULL,
    
    CONSTRAINT FK_Сотрудник_Отделение FOREIGN KEY (отделение_id) REFERENCES ОтделениеБанка(отделение_id)
);
GO



-- =====================================================
-- Таблица: БанковскийСчет
-- =====================================================
CREATE TABLE БанковскийСчет (
    счет_id INT IDENTITY(1,1) PRIMARY KEY,
    клиент_id INT NOT NULL,
    номер_счета NVARCHAR(34) NOT NULL UNIQUE,
    валюта NVARCHAR(3) NOT NULL CONSTRAINT CK_Счет_валюта CHECK (валюта IN ('RUB', 'USD', 'EUR')),
    тип_счета NVARCHAR(20) NOT NULL CONSTRAINT CK_Счет_тип CHECK (тип_счета IN ('дебетовый', 'кредитный')),
    дата_создания DATETIME2 NOT NULL DEFAULT GETDATE(),
    статус NVARCHAR(20) NOT NULL,
    
    CONSTRAINT FK_Счет_Клиент FOREIGN KEY (клиент_id) REFERENCES Клиент(клиент_id)
);
GO



-- =====================================================
-- Таблица: ЗаказНаличных
-- =====================================================
CREATE TABLE ЗаказНаличных (
    заказ_id INT IDENTITY(1,1) PRIMARY KEY,
    клиент_id INT NOT NULL,
    счет_id INT NOT NULL,
    отделение_id INT NOT NULL,
    сумма DECIMAL(15,2) NOT NULL CONSTRAINT CK_Заказ_сумма CHECK (сумма > 0),
    валюта NVARCHAR(3) NOT NULL,
    дата_запроса DATETIME2 NOT NULL DEFAULT GETDATE(),
    статус_Заказа NVARCHAR(30) NOT NULL,
    комиссия DECIMAL(10,2) NULL CONSTRAINT CK_Заказ_комиссия CHECK (комиссия >= 0),
    код_получения NVARCHAR(10) NOT NULL,
    срок_получения DATETIME2 NULL,
    назначенный_сотрудник_id INT NULL,
    выполнивший_сотрудник_id INT NULL,
    дата_выполнения DATETIME2 NULL,
    причина_отмены NVARCHAR(500) NULL,
    дата_создания DATETIME2 NOT NULL DEFAULT GETDATE(),
    дата_обновления DATETIME2 NULL,
    
    CONSTRAINT FK_Заказ_Клиент FOREIGN KEY (клиент_id) REFERENCES Клиент(клиент_id),
    CONSTRAINT FK_Заказ_Счет FOREIGN KEY (счет_id) REFERENCES БанковскийСчет(счет_id),
    CONSTRAINT FK_Заказ_Отделение FOREIGN KEY (отделение_id) REFERENCES ОтделениеБанка(отделение_id),
    CONSTRAINT FK_Заказ_НазначенныйСотрудник FOREIGN KEY (назначенный_сотрудник_id) REFERENCES Сотрудник(сотрудник_id),
    CONSTRAINT FK_Заказ_ВыполнившийСотрудник FOREIGN KEY (выполнивший_сотрудник_id) REFERENCES Сотрудник(сотрудник_id)
);
GO


-- =====================================================
-- Таблица: ДоставкаНаличных
-- =====================================================
CREATE TABLE ДоставкаНаличных (
    доставка_id INT IDENTITY(1,1) PRIMARY KEY,
    заказ_id INT NOT NULL UNIQUE,
    дата_запроса DATETIME2 NOT NULL,
    дата_доставки DATETIME2 NOT NULL,
    статус NVARCHAR(30) NOT NULL,
    инкассаторская_служба_id NVARCHAR(50) NOT NULL,
    номер_автомобиля NVARCHAR(20) NULL,
    водитель NVARCHAR(200) NULL,
    код_подтверждения_доставки NVARCHAR(20) NULL,
    принявший_сотрудник_id INT NULL,
    примечания NVARCHAR(MAX) NULL,
    
    CONSTRAINT FK_Доставка_Заказ FOREIGN KEY (заказ_id) REFERENCES ЗаказНаличных(заказ_id),
    CONSTRAINT FK_Доставка_Сотрудник FOREIGN KEY (принявший_сотрудник_id) REFERENCES Сотрудник(сотрудник_id)
);
GO


-- =====================================================
-- Таблица: Транзакция
-- =====================================================
CREATE TABLE Транзакция (
    транзакция_id INT IDENTITY(1,1) PRIMARY KEY,
    заказ_id INT NOT NULL,
    счет_id INT NOT NULL,
    тип_транзакции NVARCHAR(30) NOT NULL,
    сумма DECIMAL(15,2) NOT NULL,
    валюта NVARCHAR(3) NOT NULL,
    дата_транзакции DATETIME2 NOT NULL DEFAULT GETDATE(),
    статус NVARCHAR(20) NOT NULL,
    внешний_id_транзакции NVARCHAR(100) NULL,
    сообщение_об_ошибке NVARCHAR(MAX) NULL,
    откатная_транзакция_id INT NULL,
    
    CONSTRAINT FK_Транзакция_Заказ FOREIGN KEY (заказ_id) REFERENCES ЗаказНаличных(заказ_id),
    CONSTRAINT FK_Транзакция_Счет FOREIGN KEY (счет_id) REFERENCES БанковскийСчет(счет_id),
    CONSTRAINT FK_Транзакция_Откат FOREIGN KEY (откатная_транзакция_id) REFERENCES Транзакция(транзакция_id)
);
GO


-- =====================================================
-- Таблица: Лимит
-- =====================================================
CREATE TABLE Лимит (
    лимит_id INT IDENTITY(1,1) PRIMARY KEY,
    клиент_id INT NOT NULL,
    тип_лимита NVARCHAR(30) NOT NULL CONSTRAINT CK_Лимит_тип CHECK (тип_лимита IN ('дневной', 'месячный', 'макс_заказ')),
    сумма_лимита DECIMAL(15,2) NOT NULL,
    начало_периода DATE NOT NULL,
    конец_периода DATE NOT NULL,
    текущее_использование DECIMAL(15,2) NULL,
    дата_последнего_сброса DATE NULL,
    
    CONSTRAINT FK_Лимит_Клиент FOREIGN KEY (клиент_id) REFERENCES Клиент(клиент_id)
);
GO



-- =====================================================
-- Таблица: ПроверкаБезопасности
-- =====================================================
CREATE TABLE ПроверкаБезопасности (
    проверка_id INT IDENTITY(1,1) PRIMARY KEY,
    заказ_id INT NOT NULL,
    тип_проверки NVARCHAR(30) NOT NULL,
    дата_проверки DATETIME2 NOT NULL DEFAULT GETDATE(),
    статус NVARCHAR(20) NOT NULL,
    оценка_риска INT NULL CONSTRAINT CK_Проверка_риск CHECK (оценка_риска BETWEEN 0 AND 100),
    сотрудник_безопасности_id INT NULL,
    дата_решения DATETIME2 NULL,
    комментарии_решения NVARCHAR(MAX) NULL,
    причина_авто_блокировки NVARCHAR(500) NULL,
    
    CONSTRAINT FK_Проверка_Заказ FOREIGN KEY (заказ_id) REFERENCES ЗаказНаличных(заказ_id),
    CONSTRAINT FK_Проверка_Сотрудник FOREIGN KEY (сотрудник_безопасности_id) REFERENCES Сотрудник(сотрудник_id)
);
GO



-- =====================================================
-- Таблица: Уведомление
-- =====================================================
CREATE TABLE Уведомление (
    уведомление_id INT IDENTITY(1,1) PRIMARY KEY,
    заказ_id INT NOT NULL,
    тип_уведомления NVARCHAR(30) NOT NULL CONSTRAINT CK_Уведомление_тип CHECK (
        тип_уведомления IN ('статус', 'напоминание', 'проблема', 'новая_заявка', 'проверка', 'готова_выдача')
    ),
    канал NVARCHAR(20) NOT NULL,
    тема NVARCHAR(255) NOT NULL,
    сообщение NVARCHAR(MAX) NULL,
    дата_отправки DATETIME2 NOT NULL DEFAULT GETDATE(),
    статус NVARCHAR(20) NOT NULL,
    дата_прочтения DATETIME2 NULL,
    сообщение_об_ошибке NVARCHAR(MAX) NULL,
    
    CONSTRAINT FK_Уведомление_Заказ FOREIGN KEY (заказ_id) REFERENCES ЗаказНаличных(заказ_id)
);
GO


-- =====================================================
-- Таблица: УведомлениеКлиенту
-- =====================================================
CREATE TABLE УведомлениеКлиенту (
    уведомление_клиенту_id INT IDENTITY(1,1) PRIMARY KEY,
    уведомление_id INT NOT NULL,
    клиент_id INT NOT NULL,
    
    CONSTRAINT FK_УведомлениеКлиенту_Уведомление FOREIGN KEY (уведомление_id) REFERENCES Уведомление(уведомление_id),
    CONSTRAINT FK_УведомлениеКлиенту_Клиент FOREIGN KEY (клиент_id) REFERENCES Клиент(клиент_id),
    CONSTRAINT UQ_УведомлениеКлиенту_Unique UNIQUE (уведомление_id, клиент_id)
);
GO



-- =====================================================
-- Таблица: УведомлениеСотруднику
-- =====================================================
CREATE TABLE УведомлениеСотруднику (
    уведомление_сотруднику_id INT IDENTITY(1,1) PRIMARY KEY,
    уведомление_id INT NOT NULL,
    сотрудник_id INT NOT NULL,
    
    CONSTRAINT FK_УведомлениеСотруднику_Уведомление FOREIGN KEY (уведомление_id) REFERENCES Уведомление(уведомление_id),
    CONSTRAINT FK_УведомлениеСотруднику_Сотрудник FOREIGN KEY (сотрудник_id) REFERENCES Сотрудник(сотрудник_id),
    CONSTRAINT UQ_УведомлениеСотруднику_Unique UNIQUE (уведомление_id, сотрудник_id)
);
GO



-- =====================================================
-- Таблица: ИсторияСтатусовЗаказа
-- =====================================================
CREATE TABLE ИсторияСтатусовЗаказа (
    история_id INT IDENTITY(1,1) PRIMARY KEY,
    заказ_id INT NOT NULL,
    сотрудник_id INT NULL,
    старый_статус NVARCHAR(30) NOT NULL,
    новый_статус NVARCHAR(30) NOT NULL,
    дата_изменения DATETIME2 NOT NULL DEFAULT GETDATE(),
    причина_изменения NVARCHAR(500) NULL,
    ip_адрес NVARCHAR(45) NULL,
    
    CONSTRAINT FK_История_Заказ FOREIGN KEY (заказ_id) REFERENCES ЗаказНаличных(заказ_id),
    CONSTRAINT FK_История_Сотрудник FOREIGN KEY (сотрудник_id) REFERENCES Сотрудник(сотрудник_id)
);
GO



-- =====================================================
-- Таблица: НеудачныйЗаказ
-- =====================================================
CREATE TABLE НеудачныйЗаказ (
    неудачный_заказ_id INT IDENTITY(1,1) PRIMARY KEY,
    заказ_id INT NULL,
    клиент_id INT NOT NULL,
    тип_ошибки NVARCHAR(30) NOT NULL,
    дата_ошибки DATETIME2 NOT NULL DEFAULT GETDATE(),
    запрошенная_сумма DECIMAL(15,2) NULL,
    детали_ошибки NVARCHAR(MAX) NULL,
    рекомендуемое_действие NVARCHAR(500) NULL,
    повтор_разрешен BIT NOT NULL DEFAULT 1,
    дата_повтора DATETIME2 NULL,
    разрешено BIT NULL,
    дата_разрешения DATETIME2 NULL,
    
    CONSTRAINT FK_НеудачныйЗаказ_Заказ FOREIGN KEY (заказ_id) REFERENCES ЗаказНаличных(заказ_id),
    CONSTRAINT FK_НеудачныйЗаказ_Клиент FOREIGN KEY (клиент_id) REFERENCES Клиент(клиент_id)
);
GO


