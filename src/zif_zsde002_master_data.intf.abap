INTERFACE zif_zsde002_master_data
  PUBLIC .

  TYPES:
    ty_salesdocumenttype TYPE I_SalesDocumentType-SalesDocumentType,
    ty_paymentterms      TYPE I_PaymentTerms-PaymentTerms,
    ty_product           TYPE I_Product-Product,
    ty_plant             TYPE I_Plant-Plant,
    ty_storagelocation   TYPE I_StorageLocation-StorageLocation,
    ty_conditiontype     TYPE I_ConditionType-ConditionType,
    ty_currency          TYPE I_Currency-Currency.

  TYPES:
    "! Sales Area
    BEGIN OF ty_sales_area,
      salesorganization   TYPE I_SalesArea-SalesOrganization,
      distributionchannel TYPE I_SalesArea-DistributionChannel,
      division            TYPE I_SalesArea-Division,
    END OF ty_sales_area,

    "! Customer Sales Area
    BEGIN OF ty_cust_sales_area,
      salesorganization   TYPE I_CustomerSalesArea-SalesOrganization,
      distributionchannel TYPE I_CustomerSalesArea-DistributionChannel,
      division            TYPE I_CustomerSalesArea-Division,
      customer            TYPE I_CustomerSalesArea-Customer,
    END OF ty_cust_sales_area,

    BEGIN OF ty_base_unit,
      product  TYPE I_ProductUnitsOfMeasure-Product,
      baseunit TYPE I_ProductUnitsOfMeasure-BaseUnit,
    END OF ty_base_unit.

  TYPES:
    tt_salesdocumenttype TYPE SORTED TABLE OF ty_salesdocumenttype
                         WITH UNIQUE KEY table_line,
    tt_paymentterms      TYPE SORTED TABLE OF ty_paymentterms
                         WITH UNIQUE KEY table_line,
    tt_product           TYPE SORTED TABLE OF ty_product
                         WITH UNIQUE KEY table_line,
    tt_plant             TYPE SORTED TABLE OF ty_plant
                         WITH UNIQUE KEY table_line,
    tt_storagelocation   TYPE SORTED TABLE OF ty_storagelocation
                         WITH UNIQUE KEY table_line,
    tt_baseunit          TYPE SORTED TABLE OF ty_base_unit
                         WITH UNIQUE KEY product baseunit,
    tt_conditiontype     TYPE SORTED TABLE OF ty_conditiontype
                         WITH UNIQUE KEY table_line,
    tt_currency          TYPE SORTED TABLE OF ty_currency
                         WITH UNIQUE KEY table_line,
    tt_sales_area        TYPE SORTED TABLE OF ty_sales_area
                         WITH UNIQUE KEY salesorganization distributionchannel division,
    tt_cust_sales_area   TYPE SORTED TABLE OF ty_cust_sales_area
                         WITH UNIQUE KEY salesorganization distributionchannel division customer.

  METHODS find_unknown_sales_area
    IMPORTING it_key           TYPE tt_sales_area
    RETURNING VALUE(rt_result) TYPE tt_sales_area.

  METHODS find_unknown_cust_sales_area
    IMPORTING it_key           TYPE tt_cust_sales_area
    RETURNING VALUE(rt_result) TYPE tt_cust_sales_area.

  METHODS find_unknown_salesdocumenttype
    IMPORTING it_key           TYPE tt_salesdocumenttype
    RETURNING VALUE(rt_result) TYPE tt_salesdocumenttype.

  METHODS find_unknown_paymentterms
    IMPORTING it_key           TYPE tt_paymentterms
    RETURNING VALUE(rt_result) TYPE tt_paymentterms.

  METHODS find_unknown_product
    IMPORTING it_key           TYPE tt_product
    RETURNING VALUE(rt_result) TYPE tt_product.

  METHODS find_unknown_plant
    IMPORTING it_key           TYPE tt_plant
    RETURNING VALUE(rt_result) TYPE tt_plant.

  METHODS find_unknown_storagelocation
    IMPORTING it_key           TYPE tt_storagelocation
    RETURNING VALUE(rt_result) TYPE tt_storagelocation.

  METHODS find_unknown_baseunit
    IMPORTING it_key           TYPE tt_baseunit
    RETURNING VALUE(rt_result) TYPE tt_baseunit.

  METHODS find_unknown_conditiontype
    IMPORTING it_key           TYPE tt_conditiontype
    RETURNING VALUE(rt_result) TYPE tt_conditiontype.

  METHODS find_unknown_currency
    IMPORTING it_key           TYPE tt_currency
    RETURNING VALUE(rt_result) TYPE tt_currency.

ENDINTERFACE.
