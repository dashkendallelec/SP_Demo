USE [master]
GO
/****** Object:  Database [DemoDB]    Script Date: 6/17/2025 5:11:48 PM ******/
CREATE DATABASE [DemoDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DemoDB', FILENAME = N'C:\Optix Demo DB\DemoDB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DemoDB_log', FILENAME = N'C:\Optix Demo DB\DemoDB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [DemoDB] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DemoDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DemoDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DemoDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [DemoDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [DemoDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [DemoDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [DemoDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [DemoDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DemoDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DemoDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DemoDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DemoDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [DemoDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DemoDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [DemoDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DemoDB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [DemoDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DemoDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DemoDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DemoDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DemoDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DemoDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DemoDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DemoDB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [DemoDB] SET  MULTI_USER 
GO
ALTER DATABASE [DemoDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DemoDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DemoDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DemoDB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [DemoDB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [DemoDB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'DemoDB', N'ON'
GO
ALTER DATABASE [DemoDB] SET QUERY_STORE = ON
GO
ALTER DATABASE [DemoDB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [DemoDB]
GO
/****** Object:  User [OptixUser]    Script Date: 6/17/2025 5:11:48 PM ******/
CREATE USER [OptixUser] FOR LOGIN [OptixUser] WITH DEFAULT_SCHEMA=[OptixUser]
GO
ALTER ROLE [db_owner] ADD MEMBER [OptixUser]
GO
/****** Object:  Schema [OptixUser]    Script Date: 6/17/2025 5:11:48 PM ******/
CREATE SCHEMA [OptixUser]
GO
/****** Object:  Table [dbo].[tblNarrowDataLog]    Script Date: 6/17/2025 5:11:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblNarrowDataLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PLC_TimeStamp] [datetime] NOT NULL,
	[SP_TimeStamp] [datetime] NOT NULL,
	[TagName] [nvarchar](50) NOT NULL,
	[Value_Real] [real] NULL,
	[Value_Int] [int] NULL,
	[Value_Bool] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tblProdData]    Script Date: 6/17/2025 5:11:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tblProdData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PLC_TS] [datetime] NOT NULL,
	[SP_TS] [datetime] NOT NULL,
	[ProdLine] [nvarchar](50) NOT NULL,
	[EquipID] [nvarchar](50) NOT NULL,
	[ProdCount] [int] NOT NULL,
	[CycleAvg] [real] NOT NULL,
	[TriggerValue] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[usp_ProdData]    Script Date: 6/17/2025 5:11:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Darren Ash -IRIS-IA
-- Create date: <06/06/2025>
-- Description:	Procedure to insert production data
-- =============================================
CREATE PROCEDURE [dbo].[usp_ProdData]
    @PLC_TS					DATETIME, --PLC Timestamp
	@ProdLine				NVARCHAR(50), --Production Line Name
	@EquipID				NVARCHAR(50), --Equipment Name
    @ProdCount				INT, --Production Count
    @CycleAvg				REAL, --Cycle Average
	@Trigger				INT,  --Trigger value from PLC
	@TransactionComplete	BIT OUTPUT,  --Bit to indicate transaction complete to PLC
	@SQLErrorNumber			INT OUTPUT, --SQL Error Number for logging issue or indication to operations
	@SQLErrorDescription	NVARCHAR(4000) OUTPUT --SQL Server Error Description
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	--Use Try for proper error handling and possible transaction rollback
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO tblProdData([PLC_TS], [SP_TS], [ProdLine], [EquipID], [ProdCount], [CycleAvg], [TriggerValue])
        VALUES (@PLC_TS, GetDate(), @ProdLine, @EquipID, @ProdCount, @CycleAvg, @Trigger);

        COMMIT TRANSACTION;

        -- Set output parameters for success
        SET @TransactionComplete = 1;
        SET @SQLErrorNumber = 0;
        SET @SQLErrorDescription = 'Inserted Data';
    END TRY
    
	--Use Catch for error handling if insert fails
	BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Set output parameters for failure
        SET @TransactionComplete = 0;
        SET @SQLErrorNumber = ERROR_NUMBER();
        SET @SQLErrorDescription = ERROR_MESSAGE();
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[usp_TagData]    Script Date: 6/17/2025 5:11:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Darren Ash -IRIS-IA
-- Create date: <06/06/2025>
-- Description:	Procedure to insert tag data in a narrow format
-- =============================================
CREATE PROCEDURE [dbo].[usp_TagData]
    @PLC_TS					DATETIME,
	@TagName				NVARCHAR(50),
	@Value_Real				REAL,
    @Value_Int				INT,
    @Value_Bool				BIT,
	@TransactionComplete	BIT OUTPUT,
	@SQLErrorNumber			INT OUTPUT,
	@SQLErrorDescription	NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO tblNarrowDataLog([PLC_TimeStamp], [SP_TimeStamp], [TagName], [Value_Real], [Value_Int], [Value_Bool] )
        VALUES (@PLC_TS, GetDate(), @TagName, @Value_Real, @Value_Int, @Value_Bool);

        COMMIT TRANSACTION;

        -- Set output parameters for success
        SET @TransactionComplete = 1;
        SET @SQLErrorNumber = 0;
        SET @SQLErrorDescription = 'Inserted Data';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Set output parameters for failure
        SET @TransactionComplete = 0;
        SET @SQLErrorNumber = ERROR_NUMBER();
        SET @SQLErrorDescription = ERROR_MESSAGE();
    END CATCH
END
GO
USE [master]
GO
ALTER DATABASE [DemoDB] SET  READ_WRITE 
GO
