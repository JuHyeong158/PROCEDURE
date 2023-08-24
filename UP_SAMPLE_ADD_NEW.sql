USE [JINI_EDU]
GO
/****** Object:  StoredProcedure [dbo].[UP_SAMPLE_ADD_NEW]    Script Date: 2023-08-23 오전 10:22:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------------------------------------------------
-- 프로시저명 : UP_SAMPLE_ADD_NEW
-- 작성자     : 배주형
-- 작성일     : 2023-08-18
-- 설명       : 신규 페이지 문서 번호 삽입
-- 예문       : EXEC UP_SAMPLE_ADD_NEW N'테스트5',N'아이템1',1,''
-------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[UP_SAMPLE_ADD_NEW]

	@TITLE			NVARCHAR(100),
	@ITEM_NO		VARCHAR(32),
	@QTY			INT,
	@RMRK			NVARCHAR(100)
AS SET NOCOUNT ON;
BEGIN
	
	--TST넣기
	DECLARE	@Prefix	NVARCHAR(3) = 'TST';

	--현재 날짜를 yyyymm 형식으로 가져옴.
	DECLARE @CurrentYearMonth NVARCHAR(6) = CONVERT(NVARCHAR(6), GETDATE(), 112);

	-- 'TB_SAMPLE' 테이블에서 이번 달에 해당하는 문서 중에서 'USE_YN'이 'Y'이고 'SUBSTRING(DOC_NO, 11, 4)'가 가장 큰 값을 선택
	DECLARE @NextDocumentNumber VARCHAR(32)
	SELECT TOP 1 @NextDocumentNumber = @Prefix + @CurrentYearMonth + '-' + RIGHT('0000' + CAST(MAX_NUMBER + 1 AS NVARCHAR(5)), 4)
	FROM (
	    SELECT SUBSTRING(DOC_NO, 11, 4) AS MAX_NUMBER
	    FROM TB_SAMPLE 
	    WHERE SUBSTRING(DOC_NO, 4, 6) = @CurrentYearMonth AND USE_YN = 'Y' AND REG_DT < DATEADD(SECOND, +845, GETDATE())
	) AS SubQuery
	ORDER BY MAX_NUMBER DESC;
	
	-- @NextDocumentNumber가 NULL인 경우에 대비하여 초기화
	IF @NextDocumentNumber IS NULL
	BEGIN
	    SET @NextDocumentNumber = @Prefix + @CurrentYearMonth + '-0001';
	END;

	-- @NextDocumentNumber로 설정한 값이 @DOC_NO에 있으면
	IF EXISTS (SELECT 1 FROM TB_SAMPLE WHERE DOC_NO = @NextDocumentNumber AND USE_YN = 'N')
	BEGIN
	    -- TB_SAMPLE에서 해당 레코드 삭제
	    DELETE FROM TB_SAMPLE WHERE DOC_NO = @NextDocumentNumber;
	END;
	
	IF EXISTS (SELECT 1 FROM TB_SAMPLE_DTL WHERE DOC_NO = @NextDocumentNumber AND USE_YN = 'N')
	BEGIN
	    -- TB_SAMPLE_DTL에서 해당 레코드 삭제
	    DELETE FROM TB_SAMPLE_DTL WHERE DOC_NO = @NextDocumentNumber;
	END;


	DECLARE @NewDTL_SEQ	INT;
	--같은 DOC_NO 중에서 DTL_SEQ의 최댓값 + 1을 @NewDTL_SEQ에 초기화시킨다. NULL값이면 DTL_SEQ는 0으로 처리
	SELECT @NewDTL_SEQ = ISNULL(MAX(DTL_SEQ), 0) +1
	FROM TB_SAMPLE_DTL
	WHERE DOC_NO = @NextDocumentNumber;

	INSERT INTO TB_SAMPLE_DTL 
	(	
		DOC_NO,
		DTL_SEQ,
		ITEM_NO,
		QTY,
		RMRK,
		USE_YN
	)
	VALUES (@NextDocumentNumber,@NewDTL_SEQ, @ITEM_NO, @QTY, @RMRK,'Y');

	--TB_SAMPLE에서 @NextDocumentNumber와 같은 DOC_NO가 존재하지 않을 때 INSERT
	IF NOT EXISTS (SELECT 1 FROM TB_SAMPLE WHERE DOC_NO = @NextDocumentNumber)
    BEGIN

	INSERT INTO TB_SAMPLE (
		DOC_NO,
		TITLE,
		REG_ID,
		REG_DT,
		UPD_ID,
		UPD_DT,
		USE_YN
	)
	VALUES (@NextDocumentNumber, @TITLE, '배주형', DATEADD(SECOND, +846, GETDATE()), '배주형', DATEADD(SECOND, +846, GETDATE()), 'Y')
	
	END;
END;
