CLASS zcl_zsde002_master_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_zsde002_master_data.
ENDCLASS.



CLASS zcl_zsde002_master_data IMPLEMENTATION.

  METHOD zif_zsde002_master_data~find_unknown_sales_area.

    DATA lr_salesorganization   TYPE RANGE OF zif_zsde002_master_data=>ty_sales_area-salesorganization.
    DATA lr_distributionchannel TYPE RANGE OF zif_zsde002_master_data=>ty_sales_area-distributionchannel.
    DATA lr_division            TYPE RANGE OF zif_zsde002_master_data=>ty_sales_area-division.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_salesorganization[ low = <lfs_key>-salesorganization ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-salesorganization )
                     TO lr_salesorganization.
      ENDIF.

      IF NOT line_exists( lr_distributionchannel[ low = <lfs_key>-distributionchannel ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-distributionchannel )
                     TO lr_distributionchannel.
      ENDIF.

      IF NOT line_exists( lr_division[ low = <lfs_key>-division ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-division )
                     TO lr_division.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_SalesArea
      FIELDS SalesOrganization,
             DistributionChannel,
             Division
      WHERE SalesOrganization   IN @lr_salesorganization
        AND DistributionChannel IN @lr_distributionchannel
        AND Division            IN @lr_division
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ salesorganization   = <lfs_key>-salesorganization
                                       distributionchannel = <lfs_key>-distributionchannel
                                       division            = <lfs_key>-division ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_cust_sales_area.

    DATA lr_salesorganization   TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-salesorganization.
    DATA lr_distributionchannel TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-distributionchannel.
    DATA lr_division            TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-division.
    DATA lr_customer            TYPE RANGE OF zif_zsde002_master_data=>ty_cust_sales_area-customer.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_salesorganization[ low = <lfs_key>-salesorganization ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-salesorganization )
                     TO lr_salesorganization.
      ENDIF.

      IF NOT line_exists( lr_distributionchannel[ low = <lfs_key>-distributionchannel ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-distributionchannel )
                     TO lr_distributionchannel.
      ENDIF.

      IF NOT line_exists( lr_division[ low = <lfs_key>-division ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-division )
                     TO lr_division.
      ENDIF.

      IF NOT line_exists( lr_customer[ low = <lfs_key>-customer ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-customer )
                     TO lr_customer.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_SalesArea AS sa
      INNER JOIN I_CustomerSalesArea AS csa
        ON  csa~SalesOrganization   = sa~SalesOrganization
        AND csa~DistributionChannel = sa~DistributionChannel
        AND csa~Division            = sa~Division
      FIELDS sa~SalesOrganization,
             sa~DistributionChannel,
             sa~Division,
             csa~Customer
      WHERE sa~SalesOrganization   IN @lr_salesorganization
        AND sa~DistributionChannel IN @lr_distributionchannel
        AND sa~Division            IN @lr_division
        AND csa~Customer           IN @lr_customer
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ SalesOrganization   = <lfs_key>-salesorganization
                                       DistributionChannel = <lfs_key>-distributionchannel
                                       Division            = <lfs_key>-division
                                       Customer            = <lfs_key>-customer ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_salesdocumenttype.

    DATA lr_salesdocumenttype TYPE RANGE OF zif_zsde002_master_data=>ty_salesdocumenttype.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_salesdocumenttype = VALUE #( FOR <lfs_for> IN it_key
                                  ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_SalesDocumentType
      FIELDS SalesDocumentType
      WHERE SalesDocumentType IN @lr_salesdocumenttype
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ SalesDocumentType = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_paymentterms.

    DATA lr_paymentterms TYPE RANGE OF zif_zsde002_master_data=>ty_paymentterms.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_paymentterms = VALUE #( FOR <lfs_for> IN it_key
                             ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_PaymentTerms
      FIELDS PaymentTerms
      WHERE PaymentTerms IN @lr_paymentterms
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ PaymentTerms = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_product.

    DATA lr_product TYPE RANGE OF zif_zsde002_master_data=>ty_product.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_product = VALUE #( FOR <lfs_for> IN it_key
                        ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_Product
      FIELDS Product
      WHERE Product IN @lr_product
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ Product = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_plant.

    DATA lr_plant TYPE RANGE OF zif_zsde002_master_data=>ty_plant.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_plant = VALUE #( FOR <lfs_for> IN it_key
                      ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_Plant
      FIELDS Plant
      WHERE Plant IN @lr_plant
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ Plant = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_storagelocation.

    DATA lr_storagelocation TYPE RANGE OF zif_zsde002_master_data=>ty_storagelocation.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_storagelocation = VALUE #( FOR <lfs_for> IN it_key
                                ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_StorageLocation
      FIELDS StorageLocation
      WHERE StorageLocation IN @lr_storagelocation
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ StorageLocation = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_baseunit.

    DATA lr_product  TYPE RANGE OF zif_zsde002_master_data=>ty_base_unit-product.
    DATA lr_baseunit TYPE RANGE OF zif_zsde002_master_data=>ty_base_unit-baseunit.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).

      IF NOT line_exists( lr_product[ low = <lfs_key>-product ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-product )
                     TO lr_product.
      ENDIF.

      IF NOT line_exists( lr_baseunit[ low = <lfs_key>-baseunit ] ).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <lfs_key>-baseunit )
                     TO lr_baseunit.
      ENDIF.

    ENDLOOP.

    SELECT FROM I_ProductUnitsOfMeasure
      FIELDS Product,
             BaseUnit
      WHERE Product  IN @lr_product
        AND BaseUnit IN @lr_baseunit
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING <lfs_key>.
      IF NOT line_exists( lt_existing[ Product  = <lfs_key>-product
                                       BaseUnit = <lfs_key>-baseunit ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_conditiontype.

    DATA lr_conditiontype TYPE RANGE OF zif_zsde002_master_data=>ty_conditiontype.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_conditiontype = VALUE #( FOR <lfs_for> IN it_key
                              ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_ConditionType
      FIELDS ConditionType
      WHERE ConditionType IN @lr_conditiontype
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ ConditionType = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_zsde002_master_data~find_unknown_currency.

    DATA lr_currency TYPE RANGE OF zif_zsde002_master_data=>ty_currency.

    IF it_key IS INITIAL.
      RETURN.
    ENDIF.

    lr_currency = VALUE #( FOR <lfs_for> IN it_key
                         ( sign = 'I' option = 'EQ' low = <lfs_for> ) ).

    SELECT FROM I_Currency
      FIELDS Currency
      WHERE Currency IN @lr_currency
      INTO TABLE @DATA(lt_existing).

    LOOP AT it_key ASSIGNING FIELD-SYMBOL(<lfs_key>).
      IF NOT line_exists( lt_existing[ Currency = <lfs_key> ] ).
        INSERT <lfs_key> INTO TABLE rt_result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
