USE [JINI_EDU]
GO
/****** Object:  StoredProcedure [dbo].[UP_SAMPLE_ADD]    Script Date: 2023-08-23 오전 10:21:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------------------------------------------------
-- 프로시저명 : UP_SAMPLE_ADD
-- 작성자     : 배주형
-- 작성일     : 2023-08-18
-- 설명       : 문서 번호 삽입
-- 예문       : EXEC UP_SAMPLE_ADD N'TST202308-0005', N'테스트5',N'아이템1',1,''
-------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[UP_SAMPLE_ADD]
	@DOC_NO		VARCHAR(32),
	@TITLE		VARCHAR(100),
	@ITEM_NO	VARCHAR(32),
	@QTY		INT,
	@RMRK		VARCHAR(100)

AS 
SET NOCOUNT ON;
BEGIN

	DECLARE @NewDTL_SEQ	INT;
	--같은 DOC_NO 중에서 DTL_SEQ의 최댓값 + 1을 @NewDTL_SEQ에 초기화시킨다. NULL값이면 DTL_SEQ는 0으로 처리
	SELECT @NewDTL_SEQ = ISNULL(MAX(DTL_SEQ), 0) +1
	FROM TB_SAMPLE_DTL
	WHERE DOC_NO = @DOC_NO;
	
	INSERT INTO TB_SAMPLE_DTL (
			DOC_NO
		,	DTL_SEQ
		,	ITEM_NO
		,	QTY
		,	RMRK
		,	USE_YN
	) VALUES (
			@DOC_NO
		,	@NewDTL_SEQ
		,	@ITEM_NO
		,	@QTY
		,	@RMRK
		,	'Y'

	)
	
	DECLARE @Updated INT;
	--같은 DOC_NO 중에서 현재 시간의 -1초와 +1초 사이에 있는 UPD_DT를 카운트
	SELECT @Updated = COUNT(*) FROM TB_SAMPLE WHERE UPD_DT >= DATEADD(SECOND, +845, GETDATE()) AND UPD_DT <= DATEADD(SECOND, +847, GETDATE()) AND DOC_NO = @DOC_NO;

	--0이면 실행
	IF @Updated = 0
	BEGIN
		UPDATE TB_SAMPLE
		SET 
		    TITLE = @TITLE,
		    UPD_ID = '배주형',
		    UPD_DT = DATEADD(SECOND, +846, GETDATE())
		WHERE DOC_NO = @DOC_NO;

		
	END
END