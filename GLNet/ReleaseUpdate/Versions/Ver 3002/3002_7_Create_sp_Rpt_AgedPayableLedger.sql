Create PROCEDURE [dbo].[sp_Rpt_AgedPayableLedger] 

@Date			varchar(25) ,
@Voucher_Date		INT = 1 , 
@Due_Date		INT = 0 , 
@Other_Voucher		INT
AS

Select Vendor_Id, Vendor_name, 
CASE WHEN GL_Balance < 0 THEN
	0
ELSE
	GL_Balance
END
AS GL_Balance
, 
CASE WHEN GL_Balance > = Current_Amount THEN
	Current_Amount
WHEN GL_Balance < 0 THEN
	0
ELSE
	GL_Balance
END
AS Current_Amount
,
CASE WHEN GL_Balance - Current_Amount > = [30-60] THEN
	[30-60]
WHEN GL_Balance - Current_Amount < 0 THEN
	0
ELSE
	GL_Balance - Current_Amount 
END
AS [30-60] 
,

CASE WHEN GL_Balance - Current_Amount - [30-60] > = [60-90] THEN
	[60-90]
WHEN GL_Balance - Current_Amount - [30-60] < 0 THEN
	0
ELSE
	GL_Balance - Current_Amount - [30-60]
END
AS [60-90] 
,

CASE WHEN GL_Balance - Current_Amount - [30-60] - [60-90] > = [90+] THEN
	[90+]
WHEN GL_Balance - Current_Amount - [30-60] - [60-90] < 0 THEN
	0
ELSE
	GL_Balance - Current_Amount - [30-60]- [60-90]
END
AS [90+]
FROM
(
Select tblGL_Balance.coa_detail_id AS Vendor_Id, tblVendor.vendor_name, ISNULL(tblGL_Balance.GL_Balance, 0) GL_Balance, ISNULL(tblCurrent_Amount.Current_Amount, 0) Current_Amount, ISNULL(tbl30_60.[30-60], 0) [30-60], ISNULL(tbl60_90.[60-90], 0) [60-90], ISNULL(tbl90Plus.[90+], 0) [90+]  FROM
(SELECT     dbo.tblGlVoucherDetail.coa_detail_id, SUM(ISNULL(dbo.tblGlVoucherDetail.credit_amount, 0)) - SUM(ISNULL(dbo.tblGlVoucherDetail.debit_amount, 0)) AS GL_Balance
FROM         dbo.tblGlVoucher INNER JOIN
                      dbo.tblGlVoucherDetail ON dbo.tblGlVoucher.voucher_id = dbo.tblGlVoucherDetail.voucher_id AND tblGlVoucher.location_id = tblGlVoucherdetail.location_id AND 
                                              tblGlVoucher.shop_id = tblGlVoucherdetail.shop_id
WHERE     

 dbo.tblGlVoucher.voucher_date <= CASE WHEN @Voucher_Date = 1  THEN CONVERT(datetime, @Date, 102) 
					ELSE	GETDATE()	
					END

AND
ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900')  <= CASE WHEN @Due_Date = 1  THEN CONVERT(datetime, @Date, 102)
					ELSE	'2099-12-31'	
					END

AND (dbo.tblGlVoucher.voucher_no <> '000000') 
AND (dbo.tblGlVoucher.other_voucher <> @Other_Voucher)
GROUP BY dbo.tblGlVoucherDetail.coa_detail_id)tblGL_Balance

LEFT JOIN 

(SELECT     dbo.tblGlVoucherDetail.coa_detail_id AS coa_detail_id, SUM(dbo.tblGlVoucherDetail.credit_amount) CURRENT_Amount
                       FROM          tblGlVoucherDetail INNER JOIN
                                              tblGlvoucher ON tblglvoucher.voucher_id = tblglvoucherdetail.voucher_id AND tblGlVoucher.location_id = tblGlVoucherdetail.location_id AND 
                                              tblGlVoucher.shop_id = tblGlVoucherdetail.shop_id
                       WHERE      
dbo.tblGlVoucher.voucher_date >= CASE WHEN @Voucher_Date = 1  THEN DATEADD(dd, -30, CONVERT(datetime, @Date, 102))
					ELSE	'01-JAN-1900'	
					END

AND
dbo.tblGlVoucher.voucher_date <= CASE WHEN @Voucher_Date = 1  THEN CONVERT(datetime, @Date, 102)
					ELSE	GETDATE()	
					END

AND 

ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') >= CASE WHEN @Due_Date = 1  THEN DATEADD(dd, -30, CONVERT(datetime, @Date, 102))
					ELSE	'01-JAN-1900'	
					END
AND
ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') <= CASE WHEN @Due_Date = 1  THEN CONVERT(datetime, @Date, 102)
					ELSE	'2099-12-31'		
					END
AND (dbo.tblGlVoucher.voucher_no <> '000000') 
AND (dbo.tblGlVoucher.other_voucher <> @Other_Voucher)
                       GROUP BY tblglvoucherdetail.coa_detail_id)tblCurrent_Amount

ON 
tblGL_Balance.coa_detail_id = tblCurrent_Amount.coa_detail_id

LEFT JOIN

(SELECT     dbo.tblGlVoucherDetail.coa_detail_id AS coa_detail_id, SUM(dbo.tblGlVoucherDetail.credit_amount) AS [30-60]
                       FROM          tblGlVoucherDetail INNER JOIN
                                              tblGlvoucher ON tblglvoucher.voucher_id = tblglvoucherdetail.voucher_id AND tblGlVoucher.location_id = tblGlVoucherdetail.location_id AND 
                                              tblGlVoucher.shop_id = tblGlVoucherdetail.shop_id
                       WHERE      
	dbo.tblGlVoucher.voucher_date >= CASE WHEN @Voucher_Date = 1  THEN DATEADD(dd, -60, CONVERT(datetime, @Date, 102))
						ELSE	'01-JAN-1900'	
						END
	
	AND
	dbo.tblGlVoucher.voucher_date <= CASE WHEN @Voucher_Date = 1  THEN DATEADD(dd, -31, CONVERT(datetime, @Date, 102))
						ELSE	GETDATE()	
						END
	
	AND 
	
	ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') >= CASE WHEN @Due_Date = 1  THEN DATEADD(dd, -60, CONVERT(datetime, @Date, 102))
						ELSE	'01-JAN-1900'	
						END
	
	AND
	ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') <= CASE WHEN @Due_Date = 1  THEN DATEADD(dd, -31, CONVERT(datetime, @Date, 102))
						ELSE	'2099-12-31'		
						END
AND (dbo.tblGlVoucher.voucher_no <> '000000') 
 AND (dbo.tblGlVoucher.other_voucher <> @Other_Voucher)
                       GROUP BY tblGlVoucherdetail.coa_detail_id)tbl30_60

ON 
tblGL_Balance.coa_detail_id = tbl30_60.coa_detail_id

LEFT JOIN 
(SELECT     dbo.tblGlVoucherDetail.coa_detail_id AS coa_detail_id, SUM(dbo.tblGlVoucherDetail.credit_amount) AS [60-90]
                       FROM          tblGlVoucherDetail INNER JOIN
                                              tblGlvoucher ON tblglvoucher.voucher_id = tblglvoucherdetail.voucher_id AND tblGlVoucher.location_id = tblGlVoucherdetail.location_id AND 
                                              tblGlVoucher.shop_id = tblGlVoucherdetail.shop_id
                       WHERE      
dbo.tblGlVoucher.voucher_date >= CASE WHEN @Voucher_Date = 1  THEN DATEADD(dd, -90, CONVERT(datetime, @Date, 102))
					ELSE	'01-JAN-1900'	
					END

AND
dbo.tblGlVoucher.voucher_date <= CASE WHEN @Voucher_Date = 1  THEN DATEADD(dd, -61, CONVERT(datetime, @Date, 102))
					ELSE	GETDATE()	
					END

AND 

ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') >= CASE WHEN @Due_Date = 1  THEN DATEADD(dd, -90, CONVERT(datetime, @Date, 102))
					ELSE	'01-JAN-1900'	
					END

AND
ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') <= CASE WHEN @Due_Date = 1  THEN DATEADD(dd, -61, CONVERT(datetime, @Date, 102))
					ELSE	'2099-12-31'		
					END
AND (dbo.tblGlVoucher.other_voucher <> @Other_Voucher)
AND (dbo.tblGlVoucher.voucher_no <> '000000') 
                       GROUP BY tblGlVoucherdetail.coa_detail_id)tbl60_90

ON

tblGL_Balance.coa_detail_id = tbl60_90.coa_detail_id

LEFT JOIN

(SELECT     dbo.tblGlVoucherDetail.coa_detail_id AS coa_detail_id, SUM(dbo.tblGlVoucherDetail.credit_amount) AS [90+]
                       FROM          tblGlVoucherDetail INNER JOIN
                                              tblGlvoucher ON tblglvoucher.voucher_id = tblglvoucherdetail.voucher_id AND tblGlVoucher.location_id = tblGlVoucherdetail.location_id AND 
                                              tblGlVoucher.shop_id = tblGlVoucherdetail.shop_id
                       WHERE      
dbo.tblGlVoucher.voucher_date < CASE WHEN @Voucher_Date = 1  THEN DATEADD(dd, -90, CONVERT(datetime, @Date, 102))
					ELSE	GETDATE()	
					END

AND
ISNULL(dbo.tblGlVoucher.due_date, '01-JAN-1900') < CASE WHEN @Due_Date = 1  THEN DATEADD(dd, -90, CONVERT(datetime, @Date, 102))
					ELSE	'2099-12-31'		
					END
AND (dbo.tblGlVoucher.voucher_no <> '000000') 
AND (dbo.tblGlVoucher.other_voucher <> @Other_Voucher)
                       GROUP BY tblGlVoucherdetail.coa_detail_id)tbl90Plus
ON

tblGL_Balance.coa_detail_id = tbl90Plus.coa_detail_id

INNER JOIN

(SELECT     dbo.tblGlCOAMainSubSubDetail.coa_detail_id AS Vendor_Id, dbo.tblGlCOAMainSubSubDetail.detail_title AS vendor_name
FROM         dbo.tblGlCOAMainSubSubDetail INNER JOIN
                      dbo.tblGlCOAMainSubSub ON dbo.tblGlCOAMainSubSubDetail.main_sub_sub_id = dbo.tblGlCOAMainSubSub.main_sub_sub_id
WHERE     (dbo.tblGlCOAMainSubSub.account_type = 'Vendor' AND tblGlCoaMainSubSubDetail.end_date IS NULL)
)tblVendor

ON 

tblGL_Balance.coa_detail_id = tblVendor.Vendor_Id)tblFinalAgeing

WHERE GL_Balance > 0


 


 

