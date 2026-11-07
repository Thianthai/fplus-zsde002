# ZSDE002 Communication Objects

สถานะบน tenant dev **IA5 / client 100** (`my442178`, Own SAP Cloud System `0M8G0E7`)
ตรวจกับหน้าจอ Communication Arrangements, Maintain Communication Users และ Communication Systems บนระบบจริงเมื่อ 2026-11-08

Communication System, Communication User และ Communication Arrangement ไม่ติดไปกับ transport ต้องสร้างเองทุก tenant

## Communication Scenario

| Object | Description | Service |
|---|---|---|
| `ZCS_SO_CREATE_IN` | SDE002 - Sales Order Creation (API) | Inbound 1 ตัว |
| `ZCS_SO_UPDATE_OUT` | SDE002 - Sales Order Update (API) | Outbound 5 ตัว |

## Communication Arrangement

| Arrangement | Scenario ID | Scenario | Communication System | ทิศทาง | User | Authentication |
|---|---|---|---|---|---|---|
| `ZCA_SO_CREATE_IN` | `ZCS_SO_CREATE_IN` | SDE002 - Sales Order Creation (API) | `SBPA_DEV` | Inbound | `SBPA_DEV` | User ID and Password |
| `ZCA_SO_UPDATE_OUT` | `ZCS_SO_UPDATE_OUT` | SDE002 - Sales Order Update (API) | `ABAP_DEV` | Outbound | `ABAP_DEV` | User ID and Password |
| `CA_SAP_COM_0109` | `SAP_COM_0109` | Sales Order Integration | `ABAP_DEV` | Inbound | `ABAP_DEV` | User ID and Password |
| `CA_SAP_COM_0157` | `SAP_COM_0157` | Customer Return Integration | `ABAP_DEV` | Inbound | `ABAP_DEV` | User ID and Password |
| `CA_SAP_COM_0158` | `SAP_COM_0158` | Credit Memo Request Integration | `ABAP_DEV` | Inbound | `ABAP_DEV` | User ID and Password |
| `CA_SAP_COM_0159` | `SAP_COM_0159` | Debit Memo Request Integration | `ABAP_DEV` | Inbound | `ABAP_DEV` | User ID and Password |

## Communication System

| System ID | System Name | Host Name | Port | Logical System | Business System |
|---|---|---|---|---|---|
| `SBPA_DEV` | Communication System for SAP Build Process Automation | `spa-api-gateway-bpi-ap-prod.cfapps.ap11.hana.ondemand.com` | 443 | `SBPA_DEV` | `SBPA_DEV` |
| `ABAP_DEV` | Communication System for ABAP Internal | `my442178-api.s4hana.cloud.sap` | ว่าง | `ABAP_DEV` | `ABAP_DEV` |

| System ID | User ขาเข้า | User ขาออก |
|---|---|---|
| `SBPA_DEV` | `SBPA_DEV` (User ID and Password) | OAuth 2.0 (Basic) ซึ่ง ZSDE002 ไม่ได้ใช้ เพราะ ZSDE002 ไม่ได้เรียกออกไปหา SBPA |
| `ABAP_DEV` | `ABAP_DEV` (User ID and Password) | `ABAP_DEV` (User ID and Password) |

ทั้งสองระบบปิด Cloud Connector

API-URL ของ tenant: `https://my442178-api.s4hana.cloud.sap`

## Communication User

| User Name | User ID | Description | ใช้ใน ZSDE002 |
|---|---|---|---|
| `SBPA_DEV` | `CC0000000002` | Interface User for SAP Build Process Automation | Inbound user ของ `ZCA_SO_CREATE_IN` |
| `ABAP_DEV` | `CC0000000004` | Interface User for ABAP Internal | Outbound user ของ `ZCA_SO_UPDATE_OUT` และ inbound user ของ `CA_SAP_COM_0109`, `0157`, `0158`, `0159` |

- ทั้งสอง user ใช้ Password และไม่มี certificate
- `User ID` คือค่าที่ระบบบันทึกเป็นผู้ทำรายการ เวลาดู short dump หรือตั้ง debug user ให้ใช้ `CC...` ไม่ใช่ `User Name`
- request จาก SBPA ทำงานด้วย `CC0000000002` ส่วน PATCH หลังสร้างเอกสารทำงานด้วย `CC0000000004`

**Communication system และ user ทั้งสองชุดใช้ร่วมกับ WRICEF อื่น** การเปลี่ยนรหัสผ่าน แก้ host หรือ lock user มีผลกับทุก arrangement ในรายการนี้

| System | จำนวน | Arrangement |
|---|---|---|
| `SBPA_DEV` | 11 | `ZCA_BILLING_CREATE`, `ZCA_BILLING_LIST_TO_RPA`, `ZCA_BILLING_QUERY`, `ZCA_CLEARING_ITEM`, `ZCA_CLEARING_RESULT`, `ZCA_DO_CREATE_IN`, `ZCA_GI_QTY_QUERY`, `ZCA_INCOMING_PYMT`, `ZCA_REJECT_BATCH`, `ZCA_REJECT_ITEM`, `ZCA_SO_CREATE_IN` |
| `ABAP_DEV` | 17 | `CA_SAP_COM_0002`, `0008`, `0106`, `0108`, `0109`, `0157`, `0158`, `0159`, `0353`, `0364`, `0740`, `ZCA_CUSTOMER_OUT`, `ZCA_DO_CREATE_OUT`, `ZCA_PRODUCTION_ORDER_QUERY`, `ZCA_SO_UPDATE_OUT`, `ZCA_WAREHOUSE_TASK_CREATE_OUT`, `ZCA_ZIME005_OUT` |

## Inbound Service

| Object | Description | Protocol | URL |
|---|---|---|---|
| `ZSDE002_SO_CREATE_HTTP` | HTTP Service ZSDE002_SO_CREATE | HTTP Service | `https://my442178-api.s4hana.cloud.sap/sap/bc/http/sap/zsde002_so_create` |

Handler class คือ `ZCL_ZSDE002_HTTP`

## Outbound Service

ทั้ง 5 ตัวอยู่ใน `ZCA_SO_UPDATE_OUT` เป็น HTTP Service, Active และ port 443

Service URL ของแต่ละตัวคือ `https://my442178-api.s4hana.cloud.sap:443` ตามด้วย Path ในตาราง ตรวจกับค่าเต็มบนหน้าจอแล้วตรงทั้ง 5 ตัว

| Object | Description | Path | ใช้กับ | ปลายทาง |
|---|---|---|---|---|
| `ZSDE002_SO_UPDATE_OUT_REST` | Sales Order Update | `/sap/opu/odata/sap/API_SALES_ORDER_SRV` | C: tax class ของ item | `CA_SAP_COM_0109` |
| `ZSDE002_RET_UPDATE_OUT_REST` | Customer Return Update | `/sap/opu/odata/sap/API_CUSTOMER_RETURN_SRV` | H: tax class ของ item | `CA_SAP_COM_0157` |
| `ZSDE002_CMR_UPDATE_OUT_REST` | Credit Memo Request Update | `/sap/opu/odata/sap/API_CREDIT_MEMO_REQUEST_SRV` | K: tax class ของ item | `CA_SAP_COM_0158` |
| `ZSDE002_DMR_UPDATE_OUT_REST` | Debit Memo Request Update | `/sap/opu/odata/sap/API_DEBIT_MEMO_REQUEST_SRV` | L: tax class ของ item | `CA_SAP_COM_0159` |
| `ZSDE002_RET_V4_UPDATE_OUT_REST` | Customer Return Update V4 | `/sap/opu/odata4/sap/api_customerreturn/srvd_a2x/sap/customerreturn/0001` | H: shipping condition ของ header | `CA_SAP_COM_0157` |

## Inbound Service ปลายทางของ self-call

ตรวจกับรายการ Inbound Services บนหน้าจอ arrangement แล้ว โดยแสดงเฉพาะตัวที่ ZSDE002 เรียก

| Arrangement | Service บนหน้าจอ | Protocol | Service URL |
|---|---|---|---|
| `CA_SAP_COM_0109` | Sales Order (A2X) | OData V2 | `https://my442178-api.s4hana.cloud.sap/sap/opu/odata/sap/API_SALES_ORDER_SRV` |
| `CA_SAP_COM_0157` | Customer Return (A2X) | OData V2 | `https://my442178-api.s4hana.cloud.sap/sap/opu/odata/sap/API_CUSTOMER_RETURN_SRV` |
| `CA_SAP_COM_0157` | Customer Return (A2X) | OData V4 | `https://my442178-api.s4hana.cloud.sap/sap/opu/odata4/sap/api_customerreturn/srvd_a2x/sap/customerreturn/0001/` |
| `CA_SAP_COM_0158` | Credit Memo Request (A2X) | OData V2 | `https://my442178-api.s4hana.cloud.sap/sap/opu/odata/sap/API_CREDIT_MEMO_REQUEST_SRV` |
| `CA_SAP_COM_0159` | Debit Memo Request (A2X) | OData V2 | `https://my442178-api.s4hana.cloud.sap/sap/opu/odata/sap/API_DEBIT_MEMO_REQUEST_SRV` |

Service อื่นใน arrangement เหล่านี้ ZSDE002 ไม่ได้เรียก

## ข้อควรระวังตอนตั้งค่า

- เพิ่ม outbound service เข้า scenario ที่มี arrangement อยู่แล้ว ระบบแสดง Active แต่ยังไม่สร้าง destination ต้องเปิด arrangement แล้วกด Edit และ Save เอง
- บน tenant อื่น ชื่อ communication system และ user เปลี่ยนตาม tenant และ `ABAP_DEV` ต้องชี้ไปที่ API host ของ tenant นั้นเอง
