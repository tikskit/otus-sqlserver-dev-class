/*
Домашнее задание:
Написать скрипт создание вашей учебной базы данных.
Написать скрипт для создания таблиц.
Добавить constraint в ваши таблицы по смыслу, через инструкцию ALTER.
Написать скрипт для добавления хотя бы одного пользователя.
*/

/*
Для выполнения данного домашнего задания разработаем учебную БД, которая содержит список ТВ-провайдеров. Для каждого провайдера существует список пакетов, которые пользователь может
подключать. У каждого пакета есть своя стоимость, которая может быть равна 0. В каждый пакет входит список телевизионных каналов. При этом канал может входить в разные пакеты одного и 
того же провайдера, а также в пакеты разных провайдеров. Для каналов может указан список передач, которые по нему показывают.

Предполагается, что цель системы в том, чтобы пользователь вводит список каналов и передач, которые ему нравятся, а система рекомендует ему операторов и пакеты - но это выходит 
за рамки задания.

В системе должно быть две роли - Editor, который может редактировать списки провайдеров и каналов. А также Customer - клиент, который хочет выбрать себе оператора, ничего не может 
редактировать, только выбирает данные
*/
USE master;
GO

CREATE DATABASE TVAdvisorDB
ON
PRIMARY
(
	NAME = PrimaryData,
	FILENAME = 'E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW10\Data\PrimaryData.mdf'
), /*В учебных целях разместим служебную информацию в отдельную файловую группу*/
FILEGROUP Content01
(
	NAME = Data01,
	FILENAME = 'E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW10\Data\Data01.ndf'
)
LOG ON
(
	NAME = Log01,
	FILENAME = 'E:\OTUS\MS SQL Server\Artifacts\otus-sqlserver-dev-class\HW10\Data\Log01.ldf'
)
GO

-- Делаем Content01 файловой группой по умолчанию, чтобы все не системные объекты попадали в неё
ALTER DATABASE TVAdvisorDB 
  MODIFY FILEGROUP Content01 DEFAULT
GO

USE TVAdvisorDB;
GO
/*Все, что относится к ТВ-контенту*/
CREATE SCHEMA TV
GO
/*Все, что относится к продавцам ТВ-контента*/
CREATE SCHEMA Market
GO

-- Создаем таблицу с провайдерами
CREATE TABLE Market.Providers(ProviderID INT PRIMARY KEY CLUSTERED, ProviderName VARCHAR(50) NOT NULL)

-- Пакеты ТВ каналов
CREATE TABLE Market.Bundles(BundleID INT PRIMARY KEY CLUSTERED, 
	ProviderID INT NOT NULL REFERENCES Market.Providers(ProviderID), 
	BundleName VARCHAR(50) NOT NULL, Cost MONEY NOT NULL)


-- Создаем таблицу с каналами
CREATE TABLE TV.Channels(ChannelID INT PRIMARY KEY CLUSTERED, ChannelName VARCHAR(50) NOT NULL)


-- Какие каналы в какие пакеты входят
CREATE TABLE Market.ChannelBundleLinks(LinkID INT PRIMARY KEY CLUSTERED,
	BundleID INT NOT NULL REFERENCES Market.Bundles(BundleID),
	ChannelID INT NOT NULL REFERENCES TV.Channels(ChannelID))


/*Добавить constraint в ваши таблицы по смыслу, через инструкцию ALTER.*/
ALTER TABLE Market.ChannelBundleLinks
ADD CONSTRAINT UniqueChannelsInBundle UNIQUE(BundleID, ChannelID)


/*
В задании еще устно было сказано, что нужно создать таблицу с типом данных XML. Тогда добавим в проект следующее. Представим, что у нас тв-каналы формирует на каждый 
день ТВ-программу в виде XML-файла, который можно распространять для различных клиентов - для сайтов и умных телевизоров, которые выкачивают эти XML и затем 
отображают у себя в меню.
*/

/*Для этого мы создадим табличную переменную со структурой соответствующей экспортируемому XML-документу. Заполним её тестовыми данными, получим схему. Используюя эту схему
создадим требуемую в условии ДЗ таблицу. А тестовые данные из табличной переменной потом поместим в эту таблицу в виде XML документов. Которые при этом пройдут валидацию*/


/*Сперва получим схему для XML*/

DECLARE @Guides TABLE(BeginsAt DATETIME NOT NULL, EndsAt DATETIME NOT NULL, ShortName NVARCHAR(200) NOT NULL, [Description] NVARCHAR(500), CHECK (BeginsAt < EndsAt))

INSERT INTO @Guides(BeginsAt, EndsAt, ShortName, [Description])
VALUES
('20190320 15:00:00', '20190320 17:59:59',  N'Кёрлинг. Чемпионат мира. Женщины. Прямая трансляция из Дании. Россия - Швеция', N'Кёрлинг в Швеции уступает по популярности хоккею и футболу. Тем не менее, представительницы этой страны с завидной регулярностью попадают в призы на мировых первенствах. Вот и на нынешнем чемпионате шведки выступают очень уверенно, и матч против них для российской команды вряд ли будет носить тренировочный характер. Поэтому нашим девушкам для победы над соперницами придется показать в этой игре весь свой максимум.'),
('20190320 18:00:00', '20190320 18:04:59',  N'Новости', 'Спортивные новости.'),
('20190320 18:05:00', '20190320 18:34:59',  N'Все на Матч!', N'Звезды российского спорта в гостях у звезд телеканала "Матч ТВ" на премьере новой ежедневной программы! Все главные события - в диалогах и репортажах со всего мира. Эксклюзивные интервью и ключевые моменты соревнований, свежие новости и глубокая аналитика от лучших спортивных экспертов, это - в программе "Все на Матч!"')

/*Теперь получаем XML-схему из этой таблицы:*/
SELECT BeginsAt, EndsAt, ShortName, [Description]
FROM @Guides
FOR XML RAW('TVShow')
	, ELEMENTS, XMLSCHEMA


--Получаем и берем отсюда схему:

--Создаем схему:
CREATE XML SCHEMA COLLECTION TVGuideSchema AS 
N'
<xsd:schema targetNamespace="urn:schemas-microsoft-com:sql:SqlRowSet3" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:sqltypes="http://schemas.microsoft.com/sqlserver/2004/sqltypes" elementFormDefault="qualified">
  <xsd:import namespace="http://schemas.microsoft.com/sqlserver/2004/sqltypes" schemaLocation="http://schemas.microsoft.com/sqlserver/2004/sqltypes/sqltypes.xsd" />
  <xsd:element name="TVShow">
    <xsd:complexType>
      <xsd:sequence>
        <xsd:element name="BeginsAt" type="sqltypes:datetime" />
        <xsd:element name="EndsAt" type="sqltypes:datetime" />
        <xsd:element name="ShortName">
          <xsd:simpleType>
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1049" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth">
              <xsd:maxLength value="200" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:element>
        <xsd:element name="Description" minOccurs="0">
          <xsd:simpleType>
            <xsd:restriction base="sqltypes:nvarchar" sqltypes:localeId="1049" sqltypes:sqlCompareOptions="IgnoreCase IgnoreKanaType IgnoreWidth">
              <xsd:maxLength value="500" />
            </xsd:restriction>
          </xsd:simpleType>
        </xsd:element>
      </xsd:sequence>
    </xsd:complexType>
  </xsd:element>
</xsd:schema>
'
GO

-- Теперь используем полученную схему для создания таблицы
CREATE TABLE TV.Guides(GuideID INT PRIMARY KEY CLUSTERED, 
	ChannelID INT NOT NULL REFERENCES TV.Channels(ChannelID), 
	[Date] Date NOT NULL, 
	XMLGuide XML(TVGuideSchema) NOT NULL)
GO


--Теперь вставляем в TV.Guides телепрограмму на один день

DECLARE @Guides TABLE(BeginsAt DATETIME NOT NULL, EndsAt DATETIME NOT NULL, ShortName NVARCHAR(200) NOT NULL, [Description] NVARCHAR(500), CHECK (BeginsAt < EndsAt))

INSERT INTO @Guides(BeginsAt, EndsAt, ShortName, [Description])
VALUES
('20190320 15:00:00', '20190320 17:59:59',  N'Кёрлинг. Чемпионат мира. Женщины. Прямая трансляция из Дании. Россия - Швеция', N'Кёрлинг в Швеции уступает по популярности хоккею и футболу. Тем не менее, представительницы этой страны с завидной регулярностью попадают в призы на мировых первенствах. Вот и на нынешнем чемпионате шведки выступают очень уверенно, и матч против них для российской команды вряд ли будет носить тренировочный характер. Поэтому нашим девушкам для победы над соперницами придется показать в этой игре весь свой максимум.'),
('20190320 18:00:00', '20190320 18:04:59',  N'Новости', 'Спортивные новости.'),
('20190320 18:05:00', '20190320 18:34:59',  N'Все на Матч!', N'Звезды российского спорта в гостях у звезд телеканала "Матч ТВ" на премьере новой ежедневной программы! Все главные события - в диалогах и репортажах со всего мира. Эксклюзивные интервью и ключевые моменты соревнований, свежие новости и глубокая аналитика от лучших спортивных экспертов, это - в программе "Все на Матч!"')

DECLARE @TodaysGuide XML(TVGuideSchema)

;WITH XMLNAMESPACES ('urn:schemas-microsoft-com:sql:SqlRowSet3' AS a) 
SELECT @TodaysGuide = (
	
	
	SELECT BeginsAt AS 'a:BeginsAt', EndsAt AS 'a:EndsAt', ShortName AS 'a:ShortName', [Description] AS 'a:Description'
	FROM @Guides 
	FOR XML RAW('a:TVShow')
	, ELEMENTS
	, TYPE
	)

-- Добавим один канал

INSERT INTO TV.Channels(ChannelID, ChannelName)
VALUES(1, 'Sports channel')

-- Вставим одну ТВ-программу
INSERT INTO TV.Guides(GuideID, ChannelID, [Date], XMLGuide)
VALUES(1, 1, GETDATE(), @TodaysGuide)


-- Создаем таблицу с передачами
CREATE TABLE TV.Show(ID INT PRIMARY KEY CLUSTERED, ShowName VARCHAR(50))

-- Добавляем к БД один логин
CREATE LOGIN Editor WITH PASSWORD = 'Pa$$w0rd'; 
