

ALTER PROCEDURE [dbo].[sp_PostDatedCheques] 

@FromDate varchar(100),
@ToDate varchar(100),
@Post		INT ,
@Other_voucher	int ,
@Bank_ID	INT,
@Location_ID	INT ,
@ChequeType	VARCHAR(10)


AS

DECLARE @sqlQuery	NVARCHAR(3000)
DECLARE @WhereClause    NVARCHAR(500)
DECLARE @FirstCol	NVARCHAR(15)
DECLARE @SecondCol	NVARCHAR(15)



SET @WhereClause = 'Where Convert(varchar(10), tblglvoucher.voucher_date, 112) >= 
convert(varchar,''' + @FromDate  + ''',112) AND Convert(varchar(10), tblglvoucher.voucher_date, 112) <= convert(varchar,''' + @ToDate + ''',112)'

IF @Post = 1 
	SET @WhereClause= @WhereClause + ' AND tblglvoucher.post= ' + cast(@Post as nvarchar(5))

IF @Bank_ID <> 0 
	SET @WhereClause = @WhereClause + ' AND tblglvoucherdetail.coa_detail_id= ' + cast(@Bank_ID as nvarchar(5)) 


IF @Location_ID <> 0 
	SET @WhereClause = @WhereClause + ' AND tblglvoucher.location_id= ' + cast(@Location_ID as nvarchar(5))


IF @Other_Voucher <> -1 
	SET @WhereClause = @WhereClause + ' AND tblglvoucher.other_voucher = ' + cast(@Other_voucher as nvarchar(5))


IF @ChequeType='BPV'
	BEGIN		
	SET @FirstCol='debit_amount'
	SET @SecondCol='credit_amount'
	SET @WhereClause = @WhereClause + ' AND voucher_type_id = ' +  cast(1 as nvarchar(2))
	END
ELSE
	BEGIN	
	SET @FirstCol='credit_amount'
	SET @SecondCol='debit_amount'
	SET @WhereClause = @WhereClause + ' AND voucher_type_id = ' +  cast(5 as nvarchar(2))
	END



SET @sqlQuery ='Select tblOtherAccounts.voucher_id, BankID, BankName, coa_detail_id, detail_title , comments, cheque_no, voucher_date, amount AS Cheque_Amount from
	(
	select voucher_id, tblglvoucherdetail.coa_detail_id, tblGlCOAMainSubSubDetail.detail_title, debit_amount, credit_amount from tblglVoucherDetail
	Inner join tblGlCOAMainSubSubDetail ON tblGlVoucherDetail.coa_detail_id=tblGlCOAMainSubSubDetail.coa_detail_id
	 where voucher_id in (
	select voucher_id from 
	(Select tblglvoucherdetail.voucher_id, debit_amount, credit_amount from TblGLvoucherDetail 
	Inner join tblglvoucher on tblglvoucherdetail.voucher_id=tblglvoucher.voucher_id and tblglvoucher.location_id=tblglvoucherdetail.location_id
	and tblglvoucher.shop_id=tblglvoucherdetail.shop_id
	' + @WhereClause + ')tblBankVIDz
	where ' +  @FirstCol  + ' =0
	)
	and ' +  @FirstCol  + '<>0
	)tblOtherAccounts
	inner join
	( 
	Select tblglvoucherdetail.voucher_id, tblglvoucherdetail.coa_detail_id BankID, tblGlCOAMainSubSubDetail.detail_title BankName, dbo.tblGlVoucherDetail.comments, tblGlVoucher.cheque_no, tblGlVoucher.voucher_date, ' +  @SecondCol  + ' AS amount from TblGLvoucherDetail 
	Inner join tblglvoucher on tblglvoucherdetail.voucher_id=tblglvoucher.voucher_id and tblglvoucher.location_id=tblglvoucherdetail.location_id
	and tblglvoucher.shop_id=tblglvoucherdetail.shop_id
	Inner join tblGlCOAMainSubSubDetail ON tblGlVoucherDetail.coa_detail_id=tblGlCOAMainSubSubDetail.coa_detail_id
	Inner join tblGlCOAMainSubSub ON tblGlCOAMainSubSubDetail.main_sub_sub_id = tblGlCOAMainSubSub.main_sub_sub_id
	' + @WhereClause + '  and account_type=''Bank''
	)tblBanks
	
	ON tblOtherAccounts.voucher_id= tblBanks.voucher_id
	Order by voucher_date'

--PRINT @sqlQuery

exec sp_executesql @sqlQuery



