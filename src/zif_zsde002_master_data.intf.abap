INTERFACE zif_zsde002_master_data
  PUBLIC .

  TYPES:
    ty_sales_document_type TYPE I_SalesDocumentType-SalesDocumentType,
    ty_payment_terms       TYPE I_PaymentTerms-PaymentTerms,
    ty_product             TYPE I_Product-Product,
    ty_plant               TYPE I_Plant-Plant,
    ty_condition_type      TYPE I_ConditionType-ConditionType,
    ty_currency            TYPE I_Currency-Currency.

  TYPES:
    "! Sales Area
    BEGIN OF ty_sales_area,
      sales_organization   TYPE I_SalesArea-SalesOrganization,
      distribution_channel TYPE I_SalesArea-DistributionChannel,
      division             TYPE I_SalesArea-Division,
    END OF ty_sales_area,

    "! Customer Sales Area
    BEGIN OF ty_cust_sales_area,
      sales_organization   TYPE I_CustomerSalesArea-SalesOrganization,
      distribution_channel TYPE I_CustomerSalesArea-DistributionChannel,
      division             TYPE I_CustomerSalesArea-Division,
      customer             TYPE I_CustomerSalesArea-Customer,
    END OF ty_cust_sales_area,

    "! UoM ที่ผูกกับ material — key คือ Product + AlternativeUnit
    BEGIN OF ty_product_unit,
      product          TYPE I_ProductUnitsOfMeasure-Product,
      alternative_unit TYPE I_ProductUnitsOfMeasure-AlternativeUnit,
    END OF ty_product_unit,

    BEGIN OF ty_storage_location,
      plant            TYPE I_StorageLocation-Plant,
      storage_location TYPE I_StorageLocation-StorageLocation,
    END OF ty_storage_location.

  TYPES:
    tt_sales_document_type TYPE SORTED TABLE OF ty_sales_document_type
                           WITH UNIQUE KEY table_line,
    tt_payment_terms       TYPE SORTED TABLE OF ty_payment_terms
                           WITH UNIQUE KEY table_line,
    tt_product             TYPE SORTED TABLE OF ty_product
                           WITH UNIQUE KEY table_line,
    tt_plant               TYPE SORTED TABLE OF ty_plant
                           WITH UNIQUE KEY table_line,
    tt_storage_location    TYPE SORTED TABLE OF ty_storage_location
                           WITH UNIQUE KEY plant storage_location,
    tt_product_unit        TYPE SORTED TABLE OF ty_product_unit
                           WITH UNIQUE KEY product alternative_unit,
    tt_condition_type      TYPE SORTED TABLE OF ty_condition_type
                           WITH UNIQUE KEY table_line,
    tt_currency            TYPE SORTED TABLE OF ty_currency
                           WITH UNIQUE KEY table_line,
    tt_sales_area          TYPE SORTED TABLE OF ty_sales_area
                           WITH UNIQUE KEY sales_organization distribution_channel division,
    tt_cust_sales_area     TYPE SORTED TABLE OF ty_cust_sales_area
                           WITH UNIQUE KEY sales_organization distribution_channel division customer.

  METHODS find_unknown_sales_area
    IMPORTING it_key           TYPE tt_sales_area
    RETURNING VALUE(rt_result) TYPE tt_sales_area.

  METHODS find_unknown_cust_sales_area
    IMPORTING it_key           TYPE tt_cust_sales_area
    RETURNING VALUE(rt_result) TYPE tt_cust_sales_area.

  METHODS find_unknown_sales_doc_type
    IMPORTING it_key           TYPE tt_sales_document_type
    RETURNING VALUE(rt_result) TYPE tt_sales_document_type.

  METHODS find_unknown_payment_terms
    IMPORTING it_key           TYPE tt_payment_terms
    RETURNING VALUE(rt_result) TYPE tt_payment_terms.

  METHODS find_unknown_product
    IMPORTING it_key           TYPE tt_product
    RETURNING VALUE(rt_result) TYPE tt_product.

  METHODS find_unknown_plant
    IMPORTING it_key           TYPE tt_plant
    RETURNING VALUE(rt_result) TYPE tt_plant.

  METHODS find_unknown_storage_location
    IMPORTING it_key           TYPE tt_storage_location
    RETURNING VALUE(rt_result) TYPE tt_storage_location.

  METHODS find_unknown_product_unit
    IMPORTING it_key           TYPE tt_product_unit
    RETURNING VALUE(rt_result) TYPE tt_product_unit.

  METHODS find_unknown_condition_type
    IMPORTING it_key           TYPE tt_condition_type
    RETURNING VALUE(rt_result) TYPE tt_condition_type.

  METHODS find_unknown_currency
    IMPORTING it_key           TYPE tt_currency
    RETURNING VALUE(rt_result) TYPE tt_currency.

ENDINTERFACE.
