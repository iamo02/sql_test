CREATE PROCEDURE [dbo].[sp_tax_invoice](
    @idate date
)
AS
BEGIN
    IF EXISTS (SELECT *
        FROM tax_invoice_transaction) OR EXISTS (SELECT *
        FROM tax_invoice) OR EXISTS (SELECT *
        FROM tax_invoice_detail) OR
        EXISTS (SELECT *
        FROM tax_credit_note_invoice) OR EXISTS (SELECT *
        FROM tax_credit_note) OR EXISTS (SELECT *
        FROM end_day_ach) OR EXISTS (SELECT *
        FROM channel_result_return)
BEGIN
        delete a from tax_invoice_transaction a join tax_invoice b on a.tax_invoice_no = b.tax_invoice_no where CONVERT(DATE, CONVERT(DATE, b.create_date)) = convert(date,convert(datetime,@idate)+1)

        delete a from tax_invoice_detail a join tax_invoice b on a.tax_invoice_no = b.tax_invoice_no where CONVERT(DATE, CONVERT(DATE, b.create_date)) = convert(date,convert(datetime,@idate)+1)

        delete a from tax_credit_note_invoice a join tax_invoice b on a.tax_invoice_no = b.tax_invoice_no where CONVERT(DATE, CONVERT(DATE, b.create_date)) = convert(date,convert(datetime,@idate)+1)

        delete tax_invoice where CONVERT(DATE, CONVERT(DATE, create_date)) = convert(date,convert(datetime,@idate)+1)

        delete tax_credit_note  where CONVERT(DATE, CONVERT(DATE, create_date)) = convert(date,convert(datetime,@idate)+1)

        delete end_day_ach where CONVERT(DATE, CONVERT(DATE, created_date)) = @idate

        delete end_day_ach_holiday where CONVERT(DATE, CONVERT(DATE, created_date)) = @idate

        delete channel_result_return where created_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+(select time_to
            from cut_of_time) AND  convert(nvarchar,convert(datetime,@idate),23)+' '+(select time_from
            from cut_of_time) and settlement_result <> 'UNMATCH'

        delete end_day_ip_contra where CONVERT(DATE, CONVERT(DATE, create_ip_contra_date_time)) = @idate and fmmott_resp_no = (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'branch'and ref_field2 = 'sum_vat_amount')
    END

    DECLARE @month1 int , @month2 int ,
	           @time_to varchar(50) = (select time_to
    from cut_of_time),
               @time_from varchar(50) = (select time_from
    from cut_of_time)--, GETDATE() datetime
    --select GETDATE() = (select convert(datetime,'2021-04-01 12:03:56.290'))
    set @month1 = (select month(convert(datetime,@idate)))
    set @month2 = (select month(convert(datetime,@idate)-1))


    -- ALIPAY
    update a set
mdr = round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) ,
merchant_fee_vat = round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2) ,
net_amount = a.amount-round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)-round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2)
from transactions a
        join merchant_config b on a.merchant_id = b.merchant_id
where channel in ('alipay') and status = 'SUCCESSFUL' and b.config_key in ('PF_AP_MERCHANT_SERVICE_FEE') and a.success_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from



    update a set
mdr = round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) ,
merchant_fee_vat = round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2) ,
net_amount = a.amount-round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)-round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2)
from transactions a
        join merchant b on a.merchant_id = b.merchant_id
        join master_biller_config c on b.master_merchant_profile_id = c.master_biller_id
where  config_key = 'PF_AP_MERCHANT_SERVICE_FEE' and b.merchant_id not in (select distinct merchant_id
        from merchant_config
        where  config_key in ('PF_AP_MERCHANT_SERVICE_FEE'))
        and channel in ('alipay') and status = 'SUCCESSFUL' and a.success_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from

    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- WECHAT
    update a set
mdr = round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) ,
merchant_fee_vat = round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2) ,
net_amount = a.amount-round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)-round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2)
from transactions a
        join merchant_config b on a.merchant_id = b.merchant_id
where channel in ('wechat') and status = 'SUCCESSFUL' and b.config_key in ('PF_WC_MERCHANT_SERVICE_FEE') and a.success_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from

    update a set
mdr = round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) ,
merchant_fee_vat = round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2) ,
net_amount = a.amount-round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)-round(round(cast(amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (0.07),2)
from transactions a
        join merchant b on a.merchant_id = b.merchant_id
        join master_biller_config c on b.master_merchant_profile_id = c.master_biller_id
where  config_key = 'PF_WC_MERCHANT_SERVICE_FEE' and b.merchant_id not in (select distinct merchant_id
        from merchant_config
        where  config_key in ('PF_WC_MERCHANT_SERVICE_FEE'))
        and channel in ('wechat') and status = 'SUCCESSFUL' and a.success_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- REFUND ALIPAY
    update a set a.mdr = b.mdr , a.mdr_vat = b.mdr_vat from tb_refund_transactions_alipay a join
        (
select
            round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) mdr ,

            round(round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (7/100.00),2) mdr_vat
, out_trade_no
        from
            (
select sum(convert(float,return_amount))sum_return_amount , out_trade_no, COUNT(out_trade_no)count_out_trade_no
            from tb_refund_transactions_alipay a
            where updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and refund_status = 'REFUNDED'
            group by out_trade_no
)A
            join transactions b on substring(a.out_trade_no,1,18) = transaction_id
            join merchant_config c on b.merchant_id = c.merchant_id
        where  config_key in ('PF_AP_MERCHANT_SERVICE_FEE')
) b on a.out_trade_no = b.out_trade_no
where a.refund_status = 'REFUNDED'
        and a.id in (SELECT max(id)
        FROM tb_refund_transactions_alipay
        where refund_status = 'REFUNDED' and updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
        GROUP BY out_trade_no)

    update a set a.mdr = b.mdr , a.mdr_vat = b.mdr_vat from tb_refund_transactions_alipay a join
        (
select
            round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) mdr ,

            round(round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (7/100.00),2) mdr_vat
, out_trade_no
        from
            (
select sum(convert(float,return_amount))sum_return_amount , out_trade_no, COUNT(out_trade_no)count_out_trade_no
            from tb_refund_transactions_alipay a
            where updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and refund_status = 'REFUNDED'
            group by out_trade_no
)A
            join transactions b on substring(a.out_trade_no,1,18) = transaction_id
            join merchant m on m.merchant_id = b.merchant_id
            join master_biller_config mb on m.master_merchant_profile_id = mb.master_biller_id
        where  config_key in ('PF_AP_MERCHANT_SERVICE_FEE') and b.merchant_id not in (select distinct merchant_id
            from merchant_config
            where  config_key in ('PF_AP_MERCHANT_SERVICE_FEE'))
) b on a.out_trade_no = b.out_trade_no
where a.refund_status = 'REFUNDED'
        and a.id in (SELECT max(id)
        FROM tb_refund_transactions_alipay
        where refund_status = 'REFUNDED' and updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
        GROUP BY out_trade_no)
    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- REFUND WECHAT
    update a set a.mdr = b.mdr , a.mdr_vat = b.mdr_vat from tb_refund_transactions_wechat a join
        (
select
            round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) mdr ,

            round(round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (7/100.00),2) mdr_vat
, out_trade_no
        from
            (
select sum(convert(float,refund_fee)/100)sum_return_amount , out_trade_no, COUNT(out_trade_no)count_out_trade_no
            from tb_refund_transactions_wechat a
            where updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and result_code = 'REFUNDED'
            group by out_trade_no
)A
            join transactions b on substring(a.out_trade_no,1,18) = transaction_id
            join merchant_config c on b.merchant_id = c.merchant_id
        where  config_key in ('PF_WC_MERCHANT_SERVICE_FEE')
) b on a.out_trade_no = b.out_trade_no
where a.result_code = 'REFUNDED'
        and a.id in (SELECT max(id)
        FROM tb_refund_transactions_wechat
        where result_code = 'REFUNDED' and updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
        GROUP BY out_trade_no)

    update a set a.mdr = b.mdr , a.mdr_vat = b.mdr_vat from tb_refund_transactions_wechat a join
        (
select
            round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2) mdr ,

            round(round(cast(a.sum_return_amount as decimal(18,2)) * (case when config_value like '%p%' then round(convert(float,REPLACE(config_value, 'P,', ' '))/100 ,2,1)
     when config_value like '%f%' then round(convert(float,REPLACE(config_value, 'F,', ' ')) ,2,1)
	 when config_value like '%n%' then 0
else '' end) ,2)* (7/100.00),2) mdr_vat
, out_trade_no
        from
            (
select sum(convert(float,refund_fee)/100)sum_return_amount , out_trade_no, COUNT(out_trade_no)count_out_trade_no
            from tb_refund_transactions_wechat a
            where updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and result_code = 'REFUNDED'
            group by out_trade_no
)A
            join transactions b on substring(a.out_trade_no,1,18) = transaction_id
            join merchant m on m.merchant_id = b.merchant_id
            join master_biller_config mb on m.master_merchant_profile_id = mb.master_biller_id
        where  config_key in ('PF_WC_MERCHANT_SERVICE_FEE') and b.merchant_id not in (select distinct merchant_id
            from merchant_config
            where  config_key in ('PF_WC_MERCHANT_SERVICE_FEE'))
) b on a.out_trade_no = b.out_trade_no
where a.result_code = 'REFUNDED'
        and a.id in (SELECT max(id)
        FROM tb_refund_transactions_wechat
        where result_code = 'REFUNDED' and updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
        GROUP BY out_trade_no)
    -------------------------------------------------------------------------------------------------------------




    IF(OBJECT_ID('tempdb..#transactions')IS NOT NULL)DROP TABLE #transactions
    --SET ANSI_NULLS OFF
    SELECT tt.merchant_id, amount, merchant_fee, customer_fee, net_amount, channel, qr_type, request_original, tt.status, terminal_id, terminal_type, transaction_id, transaction_type, dynamic_qr_id, from_account, from_bank, response_original, cause_of_failure, tt.created_date, verify_date, confirm_date, success_date, tt.updated_date, payment_id, note, mdr, merchant_fee_vat, transaction_date, trx_pan, trace_number, ref_id, visa_id, mastercard_id, static_qr_id, Latitude, Longitude, refund_trans_id_alipay, refund_amount, settlement_time , extract_time
    INTO #transactions
    FROM transactions tt left join trn_merchant_block tb on (tt.merchant_id = tb.merchant_id collate Thai_CI_AS)
    WHERE tt.channel IN ('AliPay','WeChat') AND tt.success_date  BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND tt.status in ('SUCCESSFUL','REFUNDED') and tb.block_code is null
    ORDER BY tt.success_date
    insert into #transactions
    SELECT tt.merchant_id, amount, merchant_fee, customer_fee, net_amount, channel, qr_type, request_original, tt.status, terminal_id, terminal_type, transaction_id, transaction_type, dynamic_qr_id, from_account, from_bank, response_original, cause_of_failure, tt.created_date, verify_date, confirm_date, success_date, tt.updated_date, payment_id, note, mdr, merchant_fee_vat, transaction_date, trx_pan, trace_number, ref_id, visa_id, mastercard_id, static_qr_id, Latitude, Longitude, refund_trans_id_alipay, refund_amount, settlement_time , extract_time
    FROM transactions tt left join trn_merchant_block tb on (tt.merchant_id = tb.merchant_id collate Thai_CI_AS)
    WHERE tt.channel IN ('AliPay','WeChat') AND tt.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND tt.status in ('SUCCESSFUL','REFUNDED')
        AND tb.block_code in ('C1','B1',' ') and tt.merchant_id not in (select merchant_id
        from #transactions)
    ORDER BY tt.success_date
    ;
    select *
    from #transactions

    IF(OBJECT_ID('tempdb..#add_transactions')IS NOT NULL)DROP TABLE #add_transactions
    select *
    into #add_transactions
    from
        (
			select merchant_id, CONVERT(DATE, CONVERT(DATE,success_date))n_success_date , ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY  CONVERT(DATE, CONVERT(DATE,success_date)) DESC) AS rn
        from transactions
        where merchant_id in (select distinct merchant_id
            from #transactions)
            and CONVERT(DATE, CONVERT(DATE,success_date)) < @idate
            and CONVERT(DATE, CONVERT(DATE,success_date)) is not null
			--and settlement_time is null and extract_time is not null
			) a
    where rn = '1'

    --select * from #add_transactions

    insert into #transactions
    SELECT tt.merchant_id, amount, merchant_fee, customer_fee, net_amount, channel, qr_type, request_original, tt.status, terminal_id, terminal_type, transaction_id, transaction_type, dynamic_qr_id, from_account, from_bank, response_original, cause_of_failure, tt.created_date, verify_date, confirm_date, success_date, tt.updated_date, payment_id, note, mdr, merchant_fee_vat, transaction_date, trx_pan, trace_number, ref_id, visa_id, mastercard_id, static_qr_id, Latitude, Longitude, refund_trans_id_alipay, refund_amount, settlement_time , extract_time
    FROM transactions tt
    where merchant_id in (select merchant_id
        from #add_transactions) and CONVERT(DATE, CONVERT(DATE,success_date)) in (select n_success_date
        from #add_transactions)
        and settlement_time is null and extract_time is not null
        and channel in ('WECHAT','ALIPAY')

    IF(OBJECT_ID('tempdb..#distinct_merchant_id')IS NOT NULL)DROP TABLE #distinct_merchant_id
    SELECT distinct merchant_id
    into #distinct_merchant_id
    FROM #transactions

    IF (day(@idate) = '01')
	begin
        delete tax_invoice_transaction where tax_invoice_no = 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001' and transaction_id = '000000000000000000'
        delete tax_credit_note_invoice where tax_credit_note_no = 'BS'+'16'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001' and tax_invoice_no = 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001'
        insert tax_invoice_transaction
        select 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001', '000000000000000000'
        insert tax_credit_note_invoice
        select 'BS'+'16'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001', 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001'
    end

    IF(OBJECT_ID('tempdb..#t_bs_merchant')IS NOT NULL)DROP TABLE #t_bs_merchant
    create table #t_bs_merchant
    (
        bs_code nvarchar(100)
    )
    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    IF EXISTS (SELECT *
        FROM tax_invoice_transaction) AND (@month1 - @month2 = 0)
	BEGIN
        DECLARE @count int
        SET @count = (SELECT convert(int,max(RIGHT(tax_invoice_no,5)))
        FROM tax_invoice_transaction
        where substring(tax_invoice_no,7,2) = (select substring(convert(nvarchar,(@idate),23),6,2))and substring(tax_invoice_no,5 ,2) = (select substring(convert(nvarchar,(GETDATE()),23),3,2)))

        IF(OBJECT_ID('tempdb..#bs_code2')IS NOT NULL)DROP TABLE #bs_code2
        SELECT merchant_id, convert(nvarchar,ROW_NUMBER() OVER (ORDER BY merchant_id)+@count) BS
        into #bs_code2
        FROM #distinct_merchant_id
        where merchant_id is not null and merchant_id <> ''

        IF(OBJECT_ID('tempdb..#bs_merchant2')IS NOT NULL)DROP TABLE #bs_merchant2
        SELECT 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+
			case when LEN(BS) = 1 then '0000'
					 when LEN(BS) = 2 then '000'
				   when LEN(BS) = 3 then '00'
				   when LEN(BS) = 4 then '0'
			     else '' end+BS bs_code
			, *
        into #bs_merchant2
        FROM #bs_code2

        INSERT INTO tax_invoice_transaction
            ([tax_invoice_no] , [transaction_id])
        SELECT B.bs_code as tax_invoice_no, A.transaction_id
        FROM #transactions A join #bs_merchant2 B on A.merchant_id = B.merchant_id
        where channel in ('ALIPAY','WECHAT')

        INSERT INTO #t_bs_merchant
        SELECT bs_code
        FROM #bs_merchant2
    END

    IF NOT EXISTS (SELECT *
        FROM tax_invoice_transaction) OR (@month1 - @month2 <> 0)
	BEGIN
        IF(OBJECT_ID('tempdb..#bs_code')IS NOT NULL)DROP TABLE #bs_code
        SELECT merchant_id, convert(nvarchar,ROW_NUMBER() OVER (ORDER BY merchant_id)) BS
        into #bs_code
        FROM #distinct_merchant_id
        where merchant_id is not null and merchant_id <> ''

        IF(OBJECT_ID('tempdb..#bs_merchant')IS NOT NULL)DROP TABLE #bs_merchant
        SELECT 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+
			case when LEN(BS) = 1 then '0000'
					 when LEN(BS) = 2 then '000'
				   when LEN(BS) = 3 then '00'
				   when LEN(BS) = 4 then '0'
			     else '' end+BS bs_code
			, *
        into #bs_merchant
        FROM #bs_code;

        INSERT INTO tax_invoice_transaction
            ([tax_invoice_no] , [transaction_id])
        SELECT B.bs_code as tax_invoice_no, A.transaction_id
        FROM #transactions A join #bs_merchant B on A.merchant_id = B.merchant_id
        where channel in ('ALIPAY','WECHAT')



        INSERT INTO #t_bs_merchant
        SELECT bs_code
        FROM #bs_merchant
    END

    --update tax_invoice_transaction set tax_invoice_no = 'BS'+'22'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+'00001' where tax_invoice_no is null
    --update #t_bs_merchant set bs_code = '' where bs_code is null
    -------------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    IF  EXISTS (SELECT *
    FROM tax_invoice)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO tax_invoice
            ([tax_invoice_no],[merchant_id],[service_type],[service_amount],[vat_amount],[create_date],[merchant_name],[net_amount])
        select a.tax_invoice_no, b.merchant_id, 'ค่าบริการ ส่วนลดรับ' as service_type, sum(isnull(b.mdr,0))service_amount, sum(isnull(b.merchant_fee_vat,0))vat_amount, convert(datetime2,convert(datetime,@idate)+1) create_date, c.name as      merchant_name, sum(isnull(b.mdr,0))+sum(isnull(b.merchant_fee_vat,0)) net_amount
        from tax_invoice_transaction a
            join #transactions b on a.transaction_id = b.transaction_id
            --left join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            join merchant c on b.merchant_id = c.merchant_id
        where b.channel in ('ALIPAY','WECHAT') --and  b.success_date  BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND a.tax_invoice_no collate Thai_CI_AS in (SELECT bs_code FROM #t_bs_merchant)
            AND b.status in ('SUCCESSFUL','REFUNDED')
        --AND tb.block_code in ('C1','B1') or tb.block_code is null
        group by a.tax_invoice_no,b.merchant_id,c.name
    END

    IF NOT EXISTS (SELECT *
    FROM tax_invoice)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO tax_invoice
            ([tax_invoice_no],[merchant_id],[service_type],[service_amount],[vat_amount],[create_date],[merchant_name],[net_amount])
        select a.tax_invoice_no, b.merchant_id, 'ค่าบริการ ส่วนลดรับ' as service_type, sum(isnull(b.mdr,0))service_amount, sum(isnull(b.merchant_fee_vat,0))vat_amount, convert(datetime2,convert(datetime,@idate)+1) create_date, c.name as      merchant_name, sum(isnull(b.mdr,0))+sum(isnull(b.merchant_fee_vat,0)) net_amount
        from tax_invoice_transaction a
            join #transactions b on a.transaction_id = b.transaction_id
            --left join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            join merchant c on b.merchant_id = c.merchant_id
        where b.channel in ('ALIPAY','WECHAT') --and b.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
            AND b.status in ('SUCCESSFUL','REFUNDED')
        --AND tb.block_code in ('C1','B1') or tb.block_code is null
        group by a.tax_invoice_no,b.merchant_id,c.name
    END
    -------------------------------------------------------------------------------------------------------------------------------------------------------------


    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    IF  EXISTS (SELECT *
    FROM tax_invoice_detail)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO tax_invoice_detail
            ([tax_invoice_no], [channel], [gross_amount], [disc_amount], [tax_amount], [vat_amount], [net_amount])
                    select a.tax_invoice_no, b.channel, sum(b.amount)amount, sum(isnull(b.mdr,0))mdr, 0, sum(isnull(b.merchant_fee_vat,0))merchant_fee_vat,
                sum(isnull(b.amount,0))-sum(isnull(b.mdr,0))-sum(isnull(b.merchant_fee_vat,0)) net_amount
            from tax_invoice_transaction a join transactions b on a.transaction_id = b.transaction_id
            where b.success_date  BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND a.tax_invoice_no collate Thai_CI_AS in (SELECT bs_code
                FROM #t_bs_merchant)
                AND b.status in ('SUCCESSFUL','REFUNDED')
            group by a.tax_invoice_no,b.channel
        union
            select a.tax_invoice_no, b.channel, sum(b.amount)amount, sum(isnull(b.mdr,0))mdr, 0, sum(isnull(b.merchant_fee_vat,0))merchant_fee_vat,
                sum(isnull(b.amount,0))-sum(isnull(b.mdr,0))-sum(isnull(b.merchant_fee_vat,0)) net_amount
            from tax_invoice_transaction a join transactions b on a.transaction_id = b.transaction_id
                left join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            where b.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND a.tax_invoice_no collate Thai_CI_AS in (SELECT bs_code
                FROM #t_bs_merchant)
                AND b.status in ('SUCCESSFUL','REFUNDED') AND tb.block_code in ('C1','B1',' ')
            group by a.tax_invoice_no,b.channel
    END

    IF NOT EXISTS (SELECT *
    FROM tax_invoice_detail)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO tax_invoice_detail
            ([tax_invoice_no], [channel], [gross_amount], [disc_amount], [tax_amount], [vat_amount], [net_amount])
                    select a.tax_invoice_no, b.channel, sum(b.amount)amount, sum(isnull(b.mdr,0))mdr, 0, sum(isnull(b.merchant_fee_vat,0))merchant_fee_vat,
                sum(isnull(b.amount,0))-sum(isnull(b.mdr,0))-sum(isnull(b.merchant_fee_vat,0)) net_amount
            from tax_invoice_transaction a join transactions b on a.transaction_id = b.transaction_id
            where b.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
                AND b.status in ('SUCCESSFUL','REFUNDED')
            group by a.tax_invoice_no,b.channel
        union
            select a.tax_invoice_no, b.channel, sum(b.amount)amount, sum(isnull(b.mdr,0))mdr, 0, sum(isnull(b.merchant_fee_vat,0))merchant_fee_vat,
                sum(isnull(b.amount,0))-sum(isnull(b.mdr,0))-sum(isnull(b.merchant_fee_vat,0)) net_amount
            from tax_invoice_transaction a join transactions b on a.transaction_id = b.transaction_id
                left join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            where b.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
                AND b.status in ('SUCCESSFUL','REFUNDED') AND tb.block_code in ('C1','B1',' ')
            group by a.tax_invoice_no,b.channel
    END
    -------------------------------------------------------------------------------------------------------------------------------------------------------------




    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    IF(OBJECT_ID('tempdb..#cn_transaction')IS NOT NULL)DROP TABLE #cn_transaction
    --SET ANSI_NULLS OFF
    select distinct a.tax_invoice_no , b.merchant_id
    into #cn_transaction
    from tax_invoice_transaction a
        join transactions b on a.transaction_id = b.transaction_id
            and b.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND b.status in ('SUCCESSFUL','REFUNDED')

    insert into #cn_transaction
    select distinct a.tax_invoice_no , b.merchant_id
    from tax_invoice_transaction a
        join transactions b on a.transaction_id = b.transaction_id
        join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            and b.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from AND b.status in ('SUCCESSFUL','REFUNDED')
            AND tb.block_code in ('C1','B1',' ') and a.tax_invoice_no not in (select tax_invoice_no
            from #cn_transaction)
    ;
    select *
    from #cn_transaction

    IF EXISTS (SELECT *
        FROM tax_credit_note_invoice) AND (@month1 - @month2 = 0)
	BEGIN
        DECLARE @count2 int
        SET @count2 = (SELECT convert(int,max(RIGHT(tax_credit_note_no,5)))
        FROM tax_credit_note_invoice
        where substring(tax_credit_note_no,7,2) = (select substring(convert(nvarchar,(@idate),23),6,2))and substring(tax_credit_note_no,5,2) = (select substring(convert(nvarchar,(GETDATE()),23),3,2)))

        IF(OBJECT_ID('tempdb..#cn_code2')IS NOT NULL)DROP TABLE #cn_code2
        SELECT merchant_id, convert(nvarchar,ROW_NUMBER() OVER (ORDER BY merchant_id)+@count2) BS
        into #cn_code2
        FROM #distinct_merchant_id
        where merchant_id is not null and merchant_id <> ''

        IF(OBJECT_ID('tempdb..#cn_merchant2')IS NOT NULL)DROP TABLE #cn_merchant2
        SELECT 'BS'+'16'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+
			case when LEN(BS) = 1 then '0000'
					 when LEN(BS) = 2 then '000'
				   when LEN(BS) = 3 then '00'
				   when LEN(BS) = 4 then '0'
			     else '' end+BS cn_code
			, *
        into #cn_merchant2
        FROM #cn_code2

        INSERT INTO tax_credit_note_invoice
            ([tax_credit_note_no], [tax_invoice_no])
        SELECT B.cn_code as tax_invoice_no, A.tax_invoice_no
        FROM #cn_transaction A join #cn_merchant2 B on A.merchant_id = B.merchant_id
        WHERE  a.tax_invoice_no collate Thai_CI_AS in (SELECT bs_code
        FROM #t_bs_merchant);
        select '11'
    END

    IF NOT EXISTS (SELECT *
        FROM tax_credit_note_invoice) OR (@month1 - @month2 <> 0)
	BEGIN
        IF(OBJECT_ID('tempdb..#cn_code')IS NOT NULL)DROP TABLE #cn_code
        SELECT merchant_id, convert(nvarchar,ROW_NUMBER() OVER (ORDER BY merchant_id)) BS
        into #cn_code
        FROM #distinct_merchant_id
        where merchant_id is not null and merchant_id <> ''

        IF(OBJECT_ID('tempdb..#cn_merchant')IS NOT NULL)DROP TABLE #cn_merchant
        SELECT 'BS'+'16'+substring(convert(nvarchar,YEAR(GETDATE())),3,4)+ substring(convert(nvarchar,(@idate),12),3,2)+
			case when LEN(BS) = 1 then '0000'
					 when LEN(BS) = 2 then '000'
				   when LEN(BS) = 3 then '00'
				   when LEN(BS) = 4 then '0'
			     else '' end+BS cn_code
			, *
        into #cn_merchant
        FROM #cn_code

        INSERT INTO tax_credit_note_invoice
            ([tax_credit_note_no], [tax_invoice_no])
        SELECT B.cn_code as tax_invoice_no, A.tax_invoice_no
        FROM #cn_transaction A join #cn_merchant B on A.merchant_id = B.merchant_id;
        select '22'
    END

    --update tax_credit_note_invoice set tax_credit_note_no = 'BS'+'16'+right(tax_invoice_no,9) where tax_credit_note_no is null
    -------------------------------------------------------------------------------------------------------------------------------------------------------------






    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    select merchant_id, sum(amount)sum_amount, sum(mdr)sum_mdr
    into #transactions2
    from #transactions
    where channel in ('ALIPAY','WECHAT')
    group by merchant_id
    -- แก้

    select merchant_id, cast(sum(mdr)as decimal(18,2)) sum_mdr
    into #transactions3
    from #transactions
    where channel in ('ALIPAY','WECHAT')
    group by merchant_id

    select merchant_id, cast(sum(merchant_fee_vat)as decimal(18,2)) sum_mdr_vat
    into #transactions4
    from #transactions
    where channel in ('ALIPAY','WECHAT')
    group by merchant_id

    select A.tax_invoice_no, sum(convert(float,isnull(refund_amount,0)))refund_amount, sum(convert(float,isnull(mdr,0)))mdr, sum(convert(float,isnull(mdr_vat,0)))mdr_vat
    into #new_tax_credit_note
    from
        (select A.tax_invoice_no, A.merchant_id, A.service_type, A.service_amount, A.net_amount, B.transaction_id , a.create_date
        from tax_invoice a join tax_invoice_transaction b on a.tax_invoice_no = b.tax_invoice_no) A
        left join
        (            select a.transaction_id, convert(float,cast(isnull(b.return_amount,0)as decimal(18,2))) as 'refund_amount'  , convert(float,cast(isnull(b.mdr,0)as decimal(18,2))) mdr, convert(float,cast(isnull(b.mdr_vat,0)as decimal(18,2))) mdr_vat
            from transactions a
                join tb_refund_transactions_alipay b on a.transaction_id = substring(b.out_trade_no,1,18 )
            where  b.refund_status in ('REFUNDED') and CONVERT(DATE, CONVERT(DATE, b.created_date)) = @idate
        union all
            select a.transaction_id, convert(float,cast(isnull(c.refund_fee,0)as decimal(18,2)))/100 as 'refund_amount' , convert(float,cast(isnull(c.mdr,0)as decimal(18,2))) mdr, convert(float,cast(isnull(c.mdr_vat,0)as decimal(18,2))) mdr_vat
            from
                transactions a
                join tb_refund_transactions_wechat c on  a.transaction_id = substring(c.out_trade_no,1,18)
            where  c.result_code in ('REFUNDED') and CONVERT(DATE, CONVERT(DATE, c.created_date)) = @idate) B
        on A.transaction_id = B.transaction_id
    where a.create_date = substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),1,10)
    group by A.tax_invoice_no

    IF  EXISTS (SELECT *
    FROM tax_credit_note)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO tax_credit_note
            ([merchant_id], [tax_credit_note_no], [service_fee], [price_under_invoice], [valid_value], [difference], [vat_amount], [create_date])
        select a.merchant_id, D.tax_credit_note_no, sum(c.mdr), sum(b.sum_mdr) , sum(b.sum_mdr)-sum(c.mdr), sum(c.refund_amount)-sum(c.mdr), sum(c.mdr_vat), convert(datetime,@idate)+1
        from #cn_transaction a
            join #transactions2 b on a.merchant_id = b.merchant_id
            --left join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            join #new_tax_credit_note c on a.tax_invoice_no = c.tax_invoice_no
            join tax_credit_note_invoice d on a.tax_invoice_no = d.tax_invoice_no
        WHERE  a.tax_invoice_no collate Thai_CI_AS in (SELECT bs_code
        FROM #t_bs_merchant)
        --AND tb.block_code in ('C1','B1') or tb.block_code is null
        group by a.merchant_id,a.tax_invoice_no,D.tax_credit_note_no
    END

    IF NOT EXISTS (SELECT *
    FROM tax_credit_note)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO tax_credit_note
            ([merchant_id], [tax_credit_note_no], [service_fee], [price_under_invoice], [valid_value], [difference], [vat_amount], [create_date])
        select a.merchant_id, D.tax_credit_note_no, sum(c.mdr), sum(b.sum_mdr) , sum(b.sum_mdr)-sum(c.mdr), sum(c.refund_amount)-sum(c.mdr), sum(c.mdr_vat), convert(datetime,@idate)+1
        from #cn_transaction a
            join #transactions2 b on a.merchant_id = b.merchant_id
            --left join trn_merchant_block tb on (b.merchant_id = tb.merchant_id collate Thai_CI_AS)
            join #new_tax_credit_note c on a.tax_invoice_no = c.tax_invoice_no
            join tax_credit_note_invoice d on a.tax_invoice_no = d.tax_invoice_no
        --WHERE tb.block_code in ('C1','B1') or tb.block_code is null
        group by a.merchant_id,a.tax_invoice_no,D.tax_credit_note_no
    END
    -------------------------------------------------------------------------------------------------------------------------------------------------------------







    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    select C.merchant_id, A.net_amount - C.difference diff
    into #tax_credit_note_amount
    from
        (select tax_invoice_no, sum(net_amount)net_amount
        from tax_invoice_detail
        group by tax_invoice_no)A
        join
        tax_credit_note_invoice B on A.tax_invoice_no = B.tax_invoice_no
        join
        tax_credit_note C on B.tax_credit_note_no = C.tax_credit_note_no
    where CONVERT(DATE, CONVERT(DATE, c.create_date)) = convert(date,convert(datetime,@idate)+1)



    IF  EXISTS (SELECT *
    FROM end_day_ach)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO end_day_ach
            ([ach_date], [ewallet_id], [merchant_id], [account_no], [transfer_amount], [status], [success_date], [remark], [created_date], [updated_date],[mdr],[mdr_vat],[total_amount])
        select distinct convert(datetime,@idate)+1, '0'+A.merchant_id, A.merchant_id, c.account_no, d.diff, 'CREATED', null, null, convert(datetime,@idate), null
					, A3.sum_mdr , A4.sum_mdr_vat , A.sum_amount
        from #transactions2 A
            --left join trn_merchant_block tb on (a.merchant_id = tb.merchant_id collate Thai_CI_AS)
            join #transactions3 A3 on a.merchant_id = A3.merchant_id
            join #transactions4 A4 on a.merchant_id = A4.merchant_id
            join merchant B on A.merchant_id = B.merchant_id
            join customer_account c on b.customer_info_id = c.customer_info_id
            join #tax_credit_note_amount d on A.merchant_id = d.merchant_id
        where d.diff > 0.00
    --AND tb.block_code in ('C1','B1') or tb.block_code is null
    END

    IF NOT EXISTS (SELECT *
    FROM end_day_ach)
	BEGIN
        --SET ANSI_NULLS OFF
        INSERT INTO end_day_ach
            ([ach_date], [ewallet_id], [merchant_id], [account_no], [transfer_amount], [status], [success_date], [remark], [created_date], [updated_date],[mdr],[mdr_vat],[total_amount])
        select distinct convert(datetime,@idate)+1, '0'+A.merchant_id, A.merchant_id, c.account_no, d.diff, 'CREATED', null, null, convert(datetime,@idate), null
					, A3.sum_mdr , A4.sum_mdr_vat , A.sum_amount
        from #transactions2 A
            --left join trn_merchant_block tb on (a.merchant_id = tb.merchant_id collate Thai_CI_AS)
            join #transactions3 A3 on a.merchant_id = A3.merchant_id
            join #transactions4 A4 on a.merchant_id = A4.merchant_id
            join merchant B on A.merchant_id = B.merchant_id
            join customer_account c on b.customer_info_id = c.customer_info_id
            join #tax_credit_note_amount d on A.merchant_id = d.merchant_id
        where d.diff > 0.00
    --AND tb.block_code in ('C1','B1') or tb.block_code is null
    END
    -------------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- holiday
    declare @minholiday nvarchar(10),@maxholiday nvarchar(10),@today nvarchar(100)
    set @today = 'today'+convert(nvarchar,@idate)
    set @minholiday = (select min(date_from)
    from holiday
    where updated_by = @today or status = '0')
    update holiday set status = '0' where CONVERT(DATE, CONVERT(DATE,date_from)) between @minholiday and  @idate
    ------- วันหยุด-------
    --IF EXISTS (select * from end_day_ach where CONVERT(DATE, CONVERT(DATE, created_date)) = @idate and convert(nvarchar,convert(datetime,created_date)-1,23) in (select date_from from holiday)
    --           and convert(nvarchar,convert(datetime,created_date),23) not in (select date_from from holiday))
    IF EXISTS (select *
    from end_day_ach
    where  /*CONVERT(DATE, CONVERT(DATE, created_date)) = @idate and*/  convert(nvarchar,convert(datetime,@idate)-1,23) in (select date_from
        from holiday)
        and convert(nvarchar,convert(datetime,@idate),23) not in (select date_from
        from holiday))
BEGIN
        insert into end_day_ach_holiday
        select convert(datetime,@idate)+1, ewallet_id, a.merchant_id, account_no, sum(transfer_amount)transfer_amount, 'CREATED', null, null, convert(datetime,@idate), null, sum(mdr)mdr, sum(mdr_vat)mdr_vat, sum(total_amount)total_amount
        from end_day_ach a
            left join merchant_config b on a.merchant_id = b.merchant_id
        where config_key like '%PF_WC_HOLIDAY%' and b.config_value = 'false'
            and CONVERT(DATE, CONVERT(DATE, created_date)) between(select min(date_from)
            from holiday
            where status = '0') and  @idate
        group by ewallet_id,a.merchant_id,account_no

        insert into end_day_ach_holiday
        select convert(datetime,@idate)+1, ewallet_id, a.merchant_id, account_no, sum(transfer_amount)transfer_amount, 'CREATED', null, null, convert(datetime,@idate), null, sum(mdr)mdr, sum(mdr_vat)mdr_vat, sum(total_amount)total_amount
        from end_day_ach a
            join merchant b on a.merchant_id = b.merchant_id
            join master_biller_config c on b.master_merchant_profile_id = c.master_biller_id
        where c.config_key like '%PF_WC_HOLIDAY%' and c.config_value = 'false' and a.merchant_id not in (select merchant_id
            from merchant_config
            where config_key like '%PF_WC_HOLIDAY%' and config_value = 'false')
            and CONVERT(DATE, CONVERT(DATE, a.created_date)) between(select min(date_from)
            from holiday
            where status = '0') and  @idate
        group by ewallet_id,a.merchant_id,account_no

        update holiday set status = '1',updated_by = 'today'+convert(nvarchar,@idate) where CONVERT(DATE, CONVERT(DATE,date_from)) between @minholiday and  @idate


    END

    ----- วันธรรมดา---------
    insert into end_day_ach_holiday
    select a.ach_date, a.ewallet_id, a.merchant_id, a.account_no, a.transfer_amount, a.status, a.success_date, a.remark, a.created_date, a.updated_date, a.mdr, a.mdr_vat, a.total_amount
    from end_day_ach a
        left join merchant_config b on a.merchant_id = b.merchant_id
    where config_key like '%PF_WC_HOLIDAY%' and b.config_value = 'true'
        and CONVERT(DATE, CONVERT(DATE, created_date)) = @idate

    insert into end_day_ach_holiday
    select a.ach_date, a.ewallet_id, a.merchant_id, a.account_no, a.transfer_amount, a.status, a.success_date, a.remark, a.created_date, a.updated_date, a.mdr, a.mdr_vat, a.total_amount
    from end_day_ach a
        join merchant b on a.merchant_id = b.merchant_id
        join master_biller_config c on b.master_merchant_profile_id = c.master_biller_id
    where c.config_key like '%PF_WC_HOLIDAY%' and c.config_value = 'true' and a.merchant_id not in (select merchant_id
        from merchant_config /*where config_key like '%PF_WC_HOLIDAY%' and config_value = 'true'*/)
        and CONVERT(DATE, CONVERT(DATE, a.created_date)) = @idate

    insert into end_day_ach_holiday
    select a.ach_date, a.ewallet_id, a.merchant_id, a.account_no, a.transfer_amount, a.status, a.success_date, a.remark, a.created_date, a.updated_date, a.mdr, a.mdr_vat, a.total_amount
    from end_day_ach a
        left join merchant_config b on a.merchant_id = b.merchant_id
    where config_key like '%PF_WC_HOLIDAY%' and b.config_value = 'false'
        and CONVERT(DATE, CONVERT(DATE, created_date)) = @idate and convert(nvarchar,convert(datetime,a.created_date),23) not in (select date_from
        from holiday)and convert(nvarchar,convert(datetime,a.created_date)-1,23) not in (select date_from
        from holiday)

    insert into end_day_ach_holiday
    select a.ach_date, a.ewallet_id, a.merchant_id, a.account_no, a.transfer_amount, a.status, a.success_date, a.remark, a.created_date, a.updated_date, a.mdr, a.mdr_vat, a.total_amount
    from end_day_ach a
        join merchant b on a.merchant_id = b.merchant_id
        join master_biller_config c on b.master_merchant_profile_id = c.master_biller_id
    where c.config_key like '%PF_WC_HOLIDAY%' and c.config_value = 'false' and a.merchant_id not in (select merchant_id
        from merchant_config /*where config_key like '%PF_WC_HOLIDAY%' and config_value = 'true'*/)
        and CONVERT(DATE, CONVERT(DATE, a.created_date)) = @idate and convert(nvarchar,convert(datetime,a.created_date),23) not in (select date_from
        from holiday) and convert(nvarchar,convert(datetime,a.created_date)-1,23) not in (select date_from
        from holiday)


    --update holiday set status = '1',updated_by = 'today'+convert(nvarchar,@idate) where CONVERT(DATE, CONVERT(DATE,date_from)) between @minholiday and  @idate




    -------------------------------------------------------------------------------------------------------------------------------------------------------------

    -------------------------------------------------------------------------------------------------------------------------------------------------------------
    IF EXISTS (SELECT *
    FROM channel_result_return)
BEGIN
        DELETE channel_result_return where CONVERT(DATE, CONVERT(DATE, created_date)) = @idate
    END
    --SET ANSI_NULLS OFF
    INSERT INTO channel_result_return
        ([channel] ,[transaction_id],[created_date],[transaction_amount])
    select tt.channel, tt.transaction_id, tt.created_date, tt.amount
    from #transactions tt left join trn_merchant_block tb on (tt.merchant_id = tb.merchant_id collate Thai_CI_AS)
    where channel in ('ALIPAY','WECHAT') and tt.status = 'SUCCESSFUL' and tt.channel in ('WECHAT','ALIPAY') and tt.created_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and transaction_id not in (select distinct substring(channel_transaction_id,1,18 )
        from channel_result_return
        where channel_transaction_id is not null)
    --AND tb.block_code in ('C1','B1') or tb.block_code is null

    INSERT INTO channel_result_return
        ([channel] ,[transaction_id],[created_date],[transaction_amount])
    select 'ALIPAY', out_return_no, created_date, -1*(convert(float,cast(isnull(return_amount,0)as decimal(18,2))))
    from tb_refund_transactions_alipay
    where refund_status in ('REFUND_SUCCESS','REFUNDED') and updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and out_return_no not in (select distinct channel_transaction_id
        from channel_result_return
        where channel_transaction_id is not null)

    INSERT INTO channel_result_return
        ([channel] ,[transaction_id],[created_date],[transaction_amount])
    select 'WECHAT', out_trade_no, created_date, -1*(convert(float,cast(isnull(refund_fee,0)as decimal(18,2)))/100)
    from tb_refund_transactions_wechat
    where result_code in ('SUCCESS','REFUNDED') and updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and out_trade_no not in (select distinct channel_transaction_id
        from channel_result_return
        where channel_transaction_id is not null)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------

    update a set a.settlement_time = getdate() from transactions a join #transactions b on a.transaction_id = b.transaction_id
where a.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
    --and a.channel IN ('AliPay','WeChat')

    update a set a.extract_time = getdate() from transactions a left join #transactions b on a.transaction_id = b.transaction_id
where a.success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
    --and a.channel IN ('AliPay','WeChat')
    -------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- routine body goes here, e.g.
    -- SELECT 'Navicat for SQL Server'


    select A.*
    into #end_day_ach
    from
        (
select *
        from #transactions
        where channel in ('ALIPAY','WECHAT'))A
        join
        (select a.merchant_id
        from #transactions2 A
            join #transactions3 A3 on a.merchant_id = A3.merchant_id
            join #transactions4 A4 on a.merchant_id = A4.merchant_id
            join merchant B on A.merchant_id = B.merchant_id
            join customer_account c on b.customer_info_id = c.customer_info_id
            join #tax_credit_note_amount d on A.merchant_id = d.merchant_id
        where d.diff > 0.00	 )B on a.merchant_id = b.merchant_id

    --insert into #end_day_ach
    --select * from #transactions where channel = ('PROMPTPAY')

    insert into end_day_ip_contra
    select
        '0001' as FMMOTT_CUST
, (select value
        from report_field_config
        where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'sum_net_amount') as FMMOTT_AC_NO
, '62' as FMMOTT_TRAN
, (select value
        from report_field_config
        where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'sum_net_amount') as FMMOTT_RESP_NO
, (select value
        from report_field_config
        where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'sum_net_amount') as FMMOTT_SOURCE
, a.transfer_amount as FMMOTT_AMOUNT
, substring(convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1)),9,2) + substring(convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1)),6,2) + substring(convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1)),3,2) as FMMOTT_DATE
, (select value
        from report_field_config
        where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'sum_net_amount') as FMMOTT_SUB_ACCT
, (select value
        from report_field_config
        where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'sum_net_amount') as FMMOTT_SOURCE_CODE
, b.account_no as FMMOTT_SI_ACCOUNT
, '0000000000000' as fmmott_contract_no
, substring(convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1)),9,2)+'/' + substring(convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1)),6,2)+'/' + substring(convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1)),3,2) asFMMOTT_EFFECTIVE_DATE
, right(a.merchant_id,10) as FMMOTT_REFERENCE
, '000000' as FMMOTT_TIME
, convert(nvarchar,convert(datetime2,convert(datetime,a.created_date)+1),112) as FMMOTT_ASOF_DATE
, 'QREW' as FMMOTT_APPLICATION
, convert(datetime2,@idate) AS create_ip_contra_date_time
, convert(datetime2,@idate) AS gen_ip_contra_rep_date_time
    from end_day_ach_holiday a
        join merchant M on (a.merchant_id = M.merchant_id  collate Thai_CI_AI)
        join customer_info CI on M.customer_info_id = CI.id
        join customer_account b on  CI.id = b.customer_info_id
    where a.created_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from


    update end_day_ip_contra set fmmott_amount = convert(float,fmmott_amount)*100 where CONVERT(DATE, CONVERT(DATE, create_ip_contra_date_time)) = @idate and fmmott_resp_no = (select value
        from report_field_config
        where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'branch'and ref_field2 = 'sum_vat_amount')





    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    IF EXISTS (SELECT *
    FROM end_day_gl)
BEGIN

        DELETE end_day_gl where CONVERT(DATE, CONVERT(DATE, create_gl_date_time)) = @idate and activity_transfer_type in ('ACH file','Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant','Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant')

    END

    IF(OBJECT_ID('tempdb..#ach_gl')IS NOT NULL)DROP TABLE #ach_gl
    select a.merchant_id
	, amount
	, merchant_fee
	, customer_fee
	, b.transfer_amount net_amount
	, channel
	, qr_type
	--,request_original
	, status
	, terminal_id
	, terminal_type
	, transaction_id
	, transaction_type
	, dynamic_qr_id
	, from_account
	, from_bank
	, response_original
	, cause_of_failure
	, created_date
	, verify_date
	, confirm_date
	, success_date
	, updated_date
	, payment_id
	, note
	, b.transfer_amount mdr
	, merchant_fee_vat
	, transaction_date
	, trx_pan
	, trace_number
	, ref_id
	, mastercard_id
	, visa_id
	, static_qr_id
	, Latitude
	, Longitude
	, refund_trans_id_alipay
	, refund_amount, 'payment' as WA_type
    into #ach_gl
    from
        (
select *
        from #transactions
        where channel in ('ALIPAY','WECHAT'))A
        join
        (select a.merchant_id	, a.transfer_amount
        from end_day_ach_holiday a
        where CONVERT(DATE, CONVERT(DATE, a.created_date)) = @idate )B on a.merchant_id = b.merchant_id


    IF(OBJECT_ID('tempdb..#new_ach_gl')IS NOT NULL)DROP TABLE #new_ach_gl
    select *
    into #new_ach_gl
    from (
                    select *
            from #ach_gl
        union
            --insert into #ach_gl
            select merchant_id
	, -1*(convert(float,cast(isnull(b.refund_fee,0)as decimal(18,2)))/100) amount
	, merchant_fee
	, customer_fee
	, -1*((convert(float,cast(isnull(b.refund_fee,0)as decimal(18,2)))/100)-(b.mdr+b.mdr_vat)) net_amount
	, channel
	, qr_type
	--,00  as'request_original'
	, b.result_code status
	, terminal_id
	, terminal_type
	, b.out_trade_no transaction_id
	, transaction_type
	, dynamic_qr_id
	, from_account
	, from_bank
	, response_original
	, cause_of_failure
	, b.created_date
	, verify_date
	, confirm_date
	, b.updated_date success_date
	, b.updated_date updated_date
	, payment_id
	, note
	, -1*(b.mdr) mdr
	, -1*(b.mdr_vat) merchant_fee_vat
	, transaction_date
	, trx_pan
	, trace_number
	, ref_id
	, mastercard_id
	, visa_id
	, static_qr_id
	, Latitude
	, Longitude
	, refund_trans_id_alipay
	, refund_amount, 'refund' as WA_type
            --,a.settlement_time,a.extract_time
            from #ach_gl a
                join tb_refund_transactions_wechat b on a.transaction_id = substring(b.out_trade_no,1,18 )
            where CONVERT(DATE, CONVERT(DATE, b.updated_date)) = @idate
        union
            --insert into #ach_gl
            select
                merchant_id
	, -1*(convert(float,cast(isnull(b.return_amount,0)as decimal(18,2)))) amount
	, merchant_fee
	, customer_fee
	, -1*(convert(float,cast(isnull(b.return_amount,0)as decimal(18,2)))-(b.mdr+b.mdr_vat)) net_amount
	, channel
	, qr_type
	--,00  as'request_original'
	, b.refund_status status
	, terminal_id
	, terminal_type
	, b.out_trade_no transaction_id
	, transaction_type
	, dynamic_qr_id
	, from_account
	, from_bank
	, response_original
	, cause_of_failure
	, b.created_date
	, verify_date
	, confirm_date
	, b.updated_date success_date
	, b.updated_date updated_date
	, payment_id
	, note
	, -1*(b.mdr) mdr
	, -1*(b.mdr_vat) merchant_fee_vat
	, transaction_date
	, trx_pan
	, trace_number
	, ref_id
	, mastercard_id
	, visa_id
	, static_qr_id
	, Latitude
	, Longitude
	, refund_trans_id_alipay
	, refund_amount, 'refund' as WA_type
            --,a.settlement_time,a.extract_time
            from #ach_gl a
                join tb_refund_transactions_alipay b on a.transaction_id = substring(b.out_trade_no,1,18 )
            where CONVERT(DATE, CONVERT(DATE, b.updated_date)) = @idate
)a


    IF(OBJECT_ID('tempdb..#end_day_gl')IS NOT NULL)DROP TABLE #end_day_gl
    CREATE TABLE #end_day_gl
    (
        [id] [int] IDENTITY(1,1) NOT NULL,
        [activity_transfer_type] [varchar](50) NULL,
        --[transaction_id] [varchar](50) NULL,
        [transaction_type] [varchar](50) NULL,
        [amount_type] [varchar](50) NULL,
        [channel] [varchar](50) NULL,
        [ip_contra] [int] NULL,
        [gl] [int] NULL,
        [ac_no] [varchar](50) NULL,
        [tran] [varchar](50) NULL,
        [resp_no] [varchar](50) NULL,
        [source] [varchar](50) NULL,
        [amount] [decimal](18, 2) NULL,
        [sub_acct] [varchar](50) NULL,
        [blk_desc_blkg] [varchar](50) NULL,
        [blk_appl] [varchar](50) NULL,
        [si_account] [varchar](50) NULL,
        [contract_no] [varchar](50) NULL,
        --[reference] [varchar](50) NULL,
        [success_date] [datetime2](7) NULL,
        [extracted_date] [datetime2](7) NULL,
        [ach_transfer_date] [date] NULL,
        [gen_tax_inv_tb_date] [datetime2](7) NULL,
        [gen_ach_tb_date] [datetime2](7) NULL,
        [gen_ofsa_rp_date] [datetime2](7) NULL,
        [gen_ip_contra_rp_date] [datetime2](7) NULL,
        [gen_gl_rp_date] [datetime2](7) NULL
    )


    insert into #end_day_gl

                    select
            'ACH file' AS activity_transfer_type
--,tt.transaction_id AS transaction_id
, 'payment' AS transaction_type--case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'net amount' AS amount_type
, 'PROMPTPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'account_code'and ref_field2 = 'sum_net_amount') AS ac_no
,/*case when WA_type = 'payment' then '62' else '61' end*/ '61' [tran]
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'branch'and ref_field2 = 'sum_net_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'source'and ref_field2 = 'sum_net_amount') AS source
, a.transfer_amount AS amount
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'sub_account_code'and ref_field2 = 'sum_net_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'account_name'and ref_field2 = 'sum_net_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, b.account_no AS si_account
, CI.citizen_id AS contract_no
--,right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from end_day_ach_holiday a
            join merchant M on (a.merchant_id = M.merchant_id  collate Thai_CI_AI)
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account b on  CI.id = b.customer_info_id
        where a.created_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
        --from #new_ach_gl tt
        --join merchant M on tt.merchant_id = M.merchant_id
        --join customer_info CI on M.customer_info_id = CI.id
        --join customer_account ca on CI.ID=CA.customer_info_id -- where tt.status = 'SUCCESSFUL'
        ----join end_day_ach_holiday d on tt.merchant_id = d.merchant_id

    union all
        select
            'ACH file' AS activity_transfer_type
--,tt.transaction_id AS transaction_id
, 'payment' AS transaction_type--case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'net amount' AS amount_type
, 'PROMPTPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'account_code'and ref_field2 = 'sum_net_amount') AS ac_no
,/*case when WA_type = 'payment' then '62' else '61' end*/ '62' [tran]
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'branch'and ref_field2 = 'sum_net_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'source'and ref_field2 = 'sum_net_amount') AS source
, a.transfer_amount AS amount
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'sub_account_code'and ref_field2 = 'sum_net_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'account_name'and ref_field2 = 'sum_net_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, b.account_no AS si_account
, CI.citizen_id AS contract_no
--,right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from end_day_ach_holiday a
            join merchant M on (a.merchant_id = M.merchant_id  collate Thai_CI_AI)
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account b on  CI.id = b.customer_info_id
        where a.created_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
    --from #new_ach_gl tt
    --join merchant M on tt.merchant_id = M.merchant_id
    --join customer_info CI on M.customer_info_id = CI.id
    --join customer_account ca on CI.ID=CA.customer_info_id   --where tt.status = 'SUCCESSFUL'
    ----join end_day_ach_holiday d on tt.merchant_id = d.merchant_id

    union all


        select
            'ACH file' AS activity_transfer_type
--,tt.transaction_id AS transaction_id
, 'payment' AS transaction_type--case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'vat amount' AS amount_type
, 'PROMPTPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'account_code'and ref_field2 = 'sum_vat_amount') AS ac_no
,/*case when WA_type = 'payment' then '62' else '61' end*/ '61' [tran]
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'branch'and ref_field2 = 'sum_vat_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'source'and ref_field2 = 'sum_vat_amount') AS source
, a.mdr_vat AS amount
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'sub_account_code'and ref_field2 = 'sum_vat_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'account_name'and ref_field2 = 'sum_vat_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, b.account_no AS si_account
, CI.citizen_id AS contract_no
--,right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from end_day_ach_holiday a
            join merchant M on (a.merchant_id = M.merchant_id  collate Thai_CI_AI)
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account b on  CI.id = b.customer_info_id
        where a.created_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
    --from #new_ach_gl tt
    --join merchant M on tt.merchant_id = M.merchant_id
    --join customer_info CI on M.customer_info_id = CI.id
    --join customer_account ca on CI.ID=CA.customer_info_id  -- where tt.status = 'REFUNDED'
    ----join end_day_ach_holiday d on tt.merchant_id = d.merchant_id
    union all
        select
            'ACH file' AS activity_transfer_type
--,tt.transaction_id AS transaction_id
, 'payment' AS transaction_type--case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'vat amount' AS amount_type
, 'PROMPTPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'account_code'and ref_field2 = 'sum_vat_amount') AS ac_no
,/*case when WA_type = 'payment' then '62' else '61' end*/ '62' [tran]
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'branch'and ref_field2 = 'sum_vat_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'source'and ref_field2 = 'sum_vat_amount') AS source
, a.mdr_vat AS amount
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'sub_account_code'and ref_field2 = 'sum_vat_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'ACH file' and report_field = 'Credit' and ref_field1 = 'account_name'and ref_field2 = 'sum_vat_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, b.account_no AS si_account
, CI.citizen_id AS contract_no
--,right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from end_day_ach_holiday a
            join merchant M on (a.merchant_id = M.merchant_id  collate Thai_CI_AI)
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account b on  CI.id = b.customer_info_id
        where a.created_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
    --from #new_ach_gl tt
    --join merchant M on tt.merchant_id = M.merchant_id
    --join customer_info CI on M.customer_info_id = CI.id
    --join customer_account ca on CI.ID=CA.customer_info_id   --where tt.status = 'REFUNDED'
    ----join end_day_ach_holiday d on tt.merchant_id = d.merchant_id

    insert into end_day_gl
    select
        activity_transfer_type
, fmmott_cust
, fmmott_ac_no
,/*case when ((select value from report_field_config where specific_purpose = 'ACH file' and report_field = 'Debit' and ref_field1 = 'account_code'and ref_field2 = 'sum_net_amount') = fmmott_ac_no collate Thai_CI_AI) then '61' else '62' end*/ fmmott_tran as fmmott_tran
, fmmott_resp_no
, fmmott_source
, sum(fmmott_amount)	fmmott_amount
, fmmott_date
, fmmott_sub_acct
, fmmott_blk_desc_dd
, fmmott_blk_desc_mm
, fmmott_blk_desc_blkg
, fmmott_blk_asof
, fmmott_blk_appl
, create_gl_date_time
, gen_gl_date_time
    from
        (select
            activity_transfer_type as activity_transfer_type
, '0001' as fmmott_cust
, ac_no as fmmott_ac_no
, [tran] as fmmott_tran
, resp_no as fmmott_resp_no
, source as fmmott_source
, sum(amount) as fmmott_amount
, substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),9,2) + substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),6,2) + substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),3,2) as fmmott_date	 --
, sub_acct as fmmott_sub_acct
, substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),9,2) as fmmott_blk_desc_dd
, substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),6,2) as fmmott_blk_desc_mm
, blk_desc_blkg as fmmott_blk_desc_blkg
, substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),9,2) + substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),6,2) + substring(convert(nvarchar,convert(datetime2,convert(datetime,@idate)+1)),1,4) as fmmott_blk_asof
, 'QREW' as fmmott_blk_appl
, convert(datetime2,@idate) AS create_gl_date_time
, convert(datetime2,@idate) AS gen_gl_date_time
        from #end_day_gl
        group by activity_transfer_type,transaction_type,ac_no,[tran],resp_no,sub_acct,source,blk_desc_blkg)A
    group by
activity_transfer_type
,fmmott_cust
,fmmott_ac_no
--,'00' as fmmott_tran
,fmmott_tran
,fmmott_resp_no
,fmmott_source
--,sum(fmmott_amount)	fmmott_amount
,fmmott_date
,fmmott_sub_acct
,fmmott_blk_desc_dd
,fmmott_blk_desc_mm
,fmmott_blk_desc_blkg
,fmmott_blk_asof
,fmmott_blk_appl
,create_gl_date_time
,gen_gl_date_time

    update end_day_gl set fmmott_amount = convert(float,fmmott_amount)*100  where CONVERT(DATE, CONVERT(DATE, create_gl_date_time)) = @idate and activity_transfer_type  in ('ACH file')


    ------------------------------------------------------------------------------------------------------------------------------------------------------

    IF(OBJECT_ID('tempdb..#af_hit_rule_detail')IS NOT NULL)DROP TABLE #end_day_gl2
    CREATE TABLE #end_day_gl2
    (
        [id] [int] IDENTITY(1,1) NOT NULL,
        [activity_transfer_type] [varchar](100) NULL,
        [transaction_id] [varchar](50) NULL,
        [transaction_type] [varchar](50) NULL,
        [amount_type] [varchar](50) NULL,
        [channel] [varchar](50) NULL,
        [ip_contra] [int] NULL,
        [gl] [int] NULL,
        [ac_no] [varchar](50) NULL,
        [tran] [varchar](50) NULL,
        [resp_no] [varchar](50) NULL,
        [source] [varchar](50) NULL,
        [amount] [decimal](18, 2) NULL,
        [sub_acct] [varchar](50) NULL,
        [blk_desc_blkg] [varchar](100) NULL,
        [blk_appl] [varchar](50) NULL,
        [si_account] [varchar](50) NULL,
        [contract_no] [varchar](50) NULL,
        [reference] [varchar](50) NULL,
        [success_date] [datetime2](7) NULL,
        [extracted_date] [datetime2](7) NULL,
        [ach_transfer_date] [date] NULL,
        [gen_tax_inv_tb_date] [datetime2](7) NULL,
        [gen_ach_tb_date] [datetime2](7) NULL,
        [gen_ofsa_rp_date] [datetime2](7) NULL,
        [gen_ip_contra_rp_date] [datetime2](7) NULL,
        [gen_gl_rp_date] [datetime2](7) NULL
    )



    IF(OBJECT_ID('tempdb..#transactions_wechat_alipay')IS NOT NULL)DROP TABLE #transactions_wechat_alipay
    SELECT *
    INTO #transactions_wechat_alipay
    FROM(
                    SELECT

                merchant_id
	, amount
	, merchant_fee
	, customer_fee
	, net_amount
	, a.channel
	, qr_type
	, request_original
	, status
	, terminal_id
	, terminal_type
	, a.transaction_id
	, transaction_type
	, dynamic_qr_id
	, from_account
	, from_bank
	, response_original
	, cause_of_failure
	, a.created_date
	, verify_date
	, confirm_date
	, success_date
	, a.updated_date
	, payment_id
	, note
	, mdr
	, merchant_fee_vat
	, transaction_date
	, trx_pan
	, trace_number
	, ref_id
	, mastercard_id
	, visa_id
	, static_qr_id
	, Latitude
	, Longitude
	, refund_trans_id_alipay
	, refund_amount
	, 'payment' as WA_type
            FROM #transactions a
                join channel_result_return b on a.transaction_id = substring(b.channel_transaction_id,1,18 )
            where status = 'SUCCESSFUL' AND a.channel in ('ALIPAY','WECHAT') AND success_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from
                and b.channel_transaction_type_id = '1'
                and settlement_result = 'UNMATCH'

        union all

            SELECT

                merchant_id
	, -1*(convert(float,cast(isnull(b.return_amount,0)as decimal(18,2)))) amount
	, merchant_fee
	, customer_fee
	, -1*(convert(float,cast(isnull(b.return_amount,0)as decimal(18,2)))-(b.mdr+b.mdr_vat)) net_amount
	, a.channel
	, qr_type
	, request_original
	, b.refund_status status
	, terminal_id
	, terminal_type
	, b.out_return_no transaction_id
	, transaction_type
	, dynamic_qr_id
	, from_account
	, from_bank
	, response_original
	, cause_of_failure
	, b.created_date
	, verify_date
	, confirm_date
	, b.updated_date success_date
	, b.updated_date updated_date
	, payment_id
	, note
	, -1*(b.mdr) mdr
	, -1*(b.mdr_vat) merchant_fee_vat
	, transaction_date
	, trx_pan
	, trace_number
	, ref_id
	, mastercard_id
	, visa_id
	, static_qr_id
	, Latitude
	, Longitude
	, refund_trans_id_alipay
	, refund_amount
	, 'refund' as WA_type
            FROM #transactions a
                join tb_refund_transactions_alipay b on a.transaction_id = substring(b.out_trade_no,1,18 )
                join channel_result_return c on b.out_return_no = c.channel_transaction_id
            where  a.channel = 'ALIPAY' AND b.updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and refund_status = 'REFUNDED'
                and c.channel_transaction_type_id = '2'
                and settlement_result = 'UNMATCH'

        union all

            SELECT

                merchant_id
	, -1*(convert(float,cast(isnull(b.refund_fee,0)as decimal(18,2)))/100) amount
	, merchant_fee
	, customer_fee
	, -1*((convert(float,cast(isnull(b.refund_fee,0)as decimal(18,2)))/100)-(b.mdr+b.mdr_vat)) net_amount
	, a.channel
	, qr_type
	, request_original
	, b.result_code status
	, terminal_id
	, terminal_type
	, b.out_trade_no transaction_id
	, transaction_type
	, dynamic_qr_id
	, from_account
	, from_bank
	, response_original
	, cause_of_failure
	, b.created_date
	, verify_date
	, confirm_date
	, b.updated_date success_date
	, b.updated_date updated_date
	, payment_id
	, note
	, -1*(b.mdr) mdr
	, -1*(b.mdr_vat) merchant_fee_vat
	, transaction_date
	, trx_pan
	, trace_number
	, ref_id
	, mastercard_id
	, visa_id
	, static_qr_id
	, Latitude
	, Longitude
	, refund_trans_id_alipay
	, refund_amount
	, 'refund' as WA_type
            FROM #transactions a
                join tb_refund_transactions_wechat b on a.transaction_id = substring(b.out_trade_no,1,18 )
                join channel_result_return c on b.out_trade_no = c.channel_transaction_id
            where  a.channel = 'WECHAT' AND b.updated_date BETWEEN  convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and result_code = 'REFUNDED'
                and c.channel_transaction_type_id = '2'
                and settlement_result = 'UNMATCH'
)A

    --select * from #transactions_wechat_alipay where channel = 'ALIPAY'

    --ALIPAY

    insert into #end_day_gl2
    --1
                    select
            'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'amount' AS amount_type
, 'ALIPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Debit' and ref_field1 = 'account_code') AS ac_no
, case when WA_type = 'payment' then '61' else '62' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Debit' and ref_field1 = 'branch')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Debit' and ref_field1 = 'source') AS source
, tt.amount AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Debit' and ref_field1 = 'sub_account_code') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Debit' and ref_field1 = 'account_name') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'ALIPAY'
        --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)

    union all
        --2
        select
            'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'net amount' AS amount_type
, 'ALIPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'net_amount') AS ac_no
, case when WA_type = 'payment' then '62' else '61' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'net_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'net_amount') AS source
, tt.net_amount AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'net_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_name' and ref_field2 = 'net_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'ALIPAY'
    --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)

    union all
        --- if
        --3
        select
            'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'mdr amount' AS amount_type
, 'ALIPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'mdr_amount') AS ac_no
, case when WA_type = 'payment' then '62' else '61' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'mdr_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'mdr_amount') AS source
, tt.mdr AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'mdr_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_name' and ref_field2 = 'mdr_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'ALIPAY'
    --and mdr > '0' --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)

    union all
        --4
        select
            'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'vat amount' AS amount_type
, 'ALIPAY' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'mdr_vat_amount') AS ac_no
, case when WA_type = 'payment' then '62' else '61' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'mdr_vat_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'mdr_vat_amount') AS source
, tt.merchant_fee_vat AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'mdr_vat_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_name' and ref_field2 = 'mdr_vat_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'ALIPAY'
    --and merchant_fee_vat > '0' --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)





    --WECHAT

    insert into #end_day_gl2
    --1
                    select
            'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'amount' AS amount_type
, 'WECHAT' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Debit' and ref_field1 = 'account_code') AS ac_no
, case when WA_type = 'payment' then '61' else '62' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Debit' and ref_field1 = 'branch')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Debit' and ref_field1 = 'source') AS source
, tt.amount AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Debit' and ref_field1 = 'sub_account_code') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Debit' and ref_field1 = 'account_name') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'WECHAT'
        --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)

    union
        --2
        select
            'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'net amount' AS amount_type
, 'WECHAT' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'net_amount') AS ac_no
, case when WA_type = 'payment' then '62' else '61' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'net_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'net_amount') AS source
, tt.net_amount AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'net_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_name' and ref_field2 = 'net_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'WECHAT'
    --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)

    union
        --- if
        --3
        select
            'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'mdr amount' AS amount_type
, 'WECHAT' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'mdr_amount') AS ac_no
, case when WA_type = 'payment' then '62' else '61' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'mdr_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'mdr_amount') AS source
, tt.mdr AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'mdr_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_name' and ref_field2 = 'mdr_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'WECHAT'
    --and mdr > '0' --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)

    union
        --4
        select
            'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' AS activity_transfer_type
, tt.transaction_id AS transaction_id
, case when WA_type = 'payment' then 'payment' else 'refund' end AS transaction_type
, 'vat amount' AS amount_type
, 'WECHAT' AS channel
, 0 AS ip_contra
, 1 AS gl
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_code' and ref_field2 = 'mdr_vat_amount') AS ac_no
, case when WA_type = 'payment' then '62' else '61' end [tran]
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'branch' and ref_field2 = 'mdr_vat_amount')+'000000' AS resp_no
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'source' and ref_field2 = 'mdr_vat_amount') AS source
, tt.merchant_fee_vat AS amount
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'sub_account_code' and ref_field2 = 'mdr_vat_amount') sub_acct
, (select value
            from report_field_config
            where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Credit' and ref_field1 = 'account_name' and ref_field2 = 'mdr_vat_amount') blk_desc_blkg
, 'QREW' AS blk_appl
, CA.account_no AS si_account
, CI.citizen_id AS contract_no
, right(transaction_id,10) AS reference
, convert(datetime2,@idate) AS success_date
, convert(datetime2,@idate) AS extracted_date
, null ach_transfer_date
, null gen_tax_inv_tb_date
, null gen_ach_tb_date
, null gen_ofsa_rp_date
, null gen_ip_contra_rp_date
, null gen_gl_rp_date
        from #transactions_wechat_alipay tt
            join merchant M on tt.merchant_id = M.merchant_id
            join customer_info CI on M.customer_info_id = CI.id
            join customer_account ca on CI.ID=CA.customer_info_id
        where  channel = 'WECHAT'
    --and merchant_fee_vat > '0' --and  CONVERT(DATE, CONVERT(DATE, confirm_date)) = convert(nvarchar,convert(datetime2,@idate),23)


    insert into end_day_gl
    select
        activity_transfer_type
, fmmott_cust
, fmmott_ac_no
, case when ((select value
        from report_field_config
        where specific_purpose = 'Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant' and report_field = 'Debit' and ref_field1 = 'account_code') = fmmott_ac_no collate Thai_CI_AI) then '61' else '62' end as fmmott_tran
, fmmott_resp_no
, fmmott_source
, sum(fmmott_amount)	fmmott_amount
, fmmott_date
, fmmott_sub_acct
, fmmott_blk_desc_dd
, fmmott_blk_desc_mm
, fmmott_blk_desc_blkg
, fmmott_blk_asof
, fmmott_blk_appl
, create_gl_date_time
, gen_gl_date_time
    from
        (select
            activity_transfer_type as activity_transfer_type
, '0001' as fmmott_cust
, ac_no as fmmott_ac_no
, [tran] as fmmott_tran
, resp_no as fmmott_resp_no
, source as fmmott_source
, sum(amount) as fmmott_amount
, substring(convert(nvarchar,@idate),9,2)+substring(convert(nvarchar,@idate),6,2)+substring(convert(nvarchar,@idate),3,2) as fmmott_date
, sub_acct as fmmott_sub_acct
, substring(convert(nvarchar,@idate),9,2) as fmmott_blk_desc_dd
, substring(convert(nvarchar,@idate),6,2) as fmmott_blk_desc_mm
, blk_desc_blkg as fmmott_blk_desc_blkg
, substring(convert(nvarchar,@idate),9,2)+substring(convert(nvarchar,@idate),6,2)+substring(convert(nvarchar,@idate),1,4) as fmmott_blk_asof
, 'QREW' as fmmott_blk_appl
, convert(datetime2,@idate) AS create_gl_date_time
, convert(datetime2,@idate) AS gen_gl_date_time
        from #end_day_gl2
        where channel in ('ALIPAY','WECHAT')
        group by activity_transfer_type,transaction_type,ac_no,[tran],resp_no,sub_acct,source,blk_desc_blkg)A
    group by
activity_transfer_type
,fmmott_cust
,fmmott_ac_no
--,'00' as fmmott_tran
,fmmott_resp_no
,fmmott_source
--,sum(fmmott_amount)	fmmott_amount
,fmmott_date
,fmmott_sub_acct
,fmmott_blk_desc_dd
,fmmott_blk_desc_mm
,fmmott_blk_desc_blkg
,fmmott_blk_asof
,fmmott_blk_appl
,create_gl_date_time
,gen_gl_date_time

    update end_day_gl set fmmott_amount = convert(float,fmmott_amount)*100  where CONVERT(DATE, CONVERT(DATE, create_gl_date_time)) = @idate and activity_transfer_type  in ('Re-settle unmatch transaction - WeChat (for exist on WeChat) - with Merchant','Re-settle unmatch transaction - AliPay (for exist on AliPay) - with Merchant')
    update
b set b.file_date = convert(datetime,@idate)+1 ,
b.transaction_amount = a.amount ,
b.settlement_date = GETDATE(),
settlement_result = 'MATCH',
b.created_date = a.success_date,
b.updated_date =  GETDATE(),
b.settlement_remark = null ,
b.transaction_id = a.transaction_id
from channel_result_return b join transactions a on a.transaction_id = substring(b.channel_transaction_id,1,18 )
where a.updated_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and b.channel_transaction_type_id = '1'
        and settlement_result = 'UNMATCH'

    update
b set b.file_date = convert(datetime,@idate)+1 ,
b.transaction_amount = -1*(convert(float,cast(isnull(refund_fee,0)as decimal(18,2)))/100) ,
b.settlement_date = GETDATE(),
settlement_result = 'MATCH',
b.created_date = a.updated_date,
b.updated_date =  GETDATE(),
b.settlement_remark = null ,
b.transaction_id = a.out_trade_no
from channel_result_return b join tb_refund_transactions_wechat a on a.out_trade_no = b.channel_transaction_id and -1*(convert(float,cast(isnull(a.refund_fee,0)as decimal(18,2)))/100) = b.channel_transaction_amount
where a.updated_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and b.channel_transaction_type_id = '2'
        and settlement_result = 'UNMATCH'

    update
b set b.file_date = convert(datetime,@idate)+1 ,
b.transaction_amount = -1*(convert(float,cast(isnull(return_amount,0)as decimal(18,2)))) ,
b.settlement_date = GETDATE(),
settlement_result = 'MATCH',
b.created_date = a.updated_date,
b.updated_date =  GETDATE(),
b.settlement_remark = null ,
b.transaction_id = a.out_return_no
from channel_result_return b join tb_refund_transactions_alipay a on a.out_return_no = b.channel_transaction_id and -1*(convert(float,cast(isnull(return_amount,0)as decimal(18,2)))) = b.channel_transaction_amount
where a.updated_date BETWEEN convert(nvarchar,convert(datetime,@idate)-1,23)+' '+@time_to AND  convert(nvarchar,convert(datetime,@idate),23)+' '+@time_from and b.channel_transaction_type_id = '2'
        and settlement_result = 'UNMATCH'


END
GO