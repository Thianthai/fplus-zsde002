# ZSDE002 Inbound API: Sales Order Creation

API ที่ SAP Build Process Automation (SBPA) เรียกเพื่อสร้างเอกสารขาย
ค่า URL และ user เป็นของ tenant dev (IA5) บน tenant อื่นจะเปลี่ยนตาม tenant

Communication object ทั้งหมดอยู่ใน [communication.md](communication.md)

## ข้อมูล API

| หัวข้อ | รายละเอียด |
|---|---|
| API name | `ZSDE002_SO_CREATE` (Sales Order Creation) |
| ทิศทาง | Inbound เข้า S/4HANA |
| ผู้เรียก | SAP Build Process Automation |
| Method | `POST` |
| URL (dev) | `https://my442178-api.s4hana.cloud.sap/sap/bc/http/sap/zsde002_so_create` |
| Authentication | User ID and Password (Basic) |
| User | `SBPA_DEV` (User ID `CC0000000002`) |
| Request header | `Content-Type: application/json` |
| Response header | `Content-Type: application/json` |
| Arrangement / Scenario | `ZCA_SO_CREATE_IN` / `ZCS_SO_CREATE_IN` |
| Comm System / Inbound service | `SBPA_DEV` / `ZSDE002_SO_CREATE_HTTP` |
| เอกสารที่สร้างได้ | Sales Order, Customer Return, Credit Memo Request, Debit Memo Request ตาม `SalesOrderType` |

`GET` ที่ URL เดียวกันคืนโครงสร้างตัวอย่าง ไม่ได้สร้างเอกสาร ส่วน method อื่นได้ 405

## HTTP status ของ POST

| Code | `Status` ใน body | ความหมาย |
|---|---|---|
| 200 | `S` | สำเร็จทุก order |
| 200 | `W` | สำเร็จบางส่วน ต้องอ่านผลราย order |
| 400 | `E` | ไม่มี order ไหนสำเร็จ หรือ request ใช้ไม่ได้ เช่น body ว่างหรือ JSON ผิด |

## Sample request

```http
POST /sap/bc/http/sap/zsde002_so_create
Host: my442178-api.s4hana.cloud.sap
Authorization: Basic <SBPA_DEV:password แบบ Base64>
Content-Type: application/json
```

ตัวอย่างนี้มาจากเคสจริงที่ได้เอกสาร O250000037 แต่ย่อจาก 2 item เหลือ 1 item

```json
{
  "RequestId": "20261014_114329_114331",
  "Orders": [
    {
      "SfHeaderIdRef": "b8MAz000002fJqwMAE",
      "SalesOrderTempId": "0000000001",
      "ProcessType": "120",
      "TranType": "S",
      "SalesOrderType": "CCIS",
      "SalesOrganization": "2000",
      "DistributionChannel": "60",
      "Division": "00",
      "SoldToParty": "1000000003",
      "CustomerBranch": "00000",
      "ShipToParty": "1000000003",
      "BillToParty": "1000000003",
      "Payer": "1000000003",
      "StockVan": "2000000002",
      "CustomerReference": "b8MAz000002fJqwMAE",
      "CustomerReferenceDate": "2026-10-10",
      "DocumentDate": "2026-10-10",
      "ReqDeliveryDate": "2026-10-10",
      "ShippingConditions": "Z1",
      "PaymentTransactionReference": "123456788",
      "TaxDocumentNo": "2026091401",
      "RelatedDocumentReference": "",
      "Currency": "THB",
      "PaymentTerm": "ZR00",
      "OriginalSalesDocument": "",
      "OrderReason": "",
      "OrderReasonText": "",
      "CustomerPo": "",
      "Pricings": [],
      "Items": [
        {
          "Item": "1",
          "MaterialNumber": "100000374",
          "CustomerMaterial": "",
          "ItemCategory": "",
          "RequestedQuantity": "1",
          "SalesUnit": "PC",
          "Plant": "2024",
          "StorageLocation": "",
          "MatTaxClass": "",
          "SalesText": "",
          "UnitText": "",
          "PromotionIdText": "",
          "Batch": "0000000034",
          "Route": "ZSPK07",
          "SfItemIdRef": "a2GAz000000mAmhMAE",
          "Pricings": [
            {
              "ConditionType": "ZPI1",
              "ConditionAmount": "540.00",
              "ConditionCurrency": "THB",
              "ConditionPricingUnit": "1",
              "ConditionUnitOfMeasure": "PC"
            }
          ]
        }
      ]
    }
  ]
}
```

## Sample response

### สำเร็จ: HTTP 200

Response จริงของ O250000037

```json
{
  "RequestId": "20261014_114329_114331",
  "Status": "S",
  "Orders": [
    {
      "Status": "S",
      "Code": "ZSDE002/500",
      "Message": "Document O250000037 created",
      "SalesOrderNumber": "O250000037",
      "DocumentType": "CCIS",
      "CustomerReference": "b8MAz000002fJqwMAE",
      "SfHeaderIdRef": "b8MAz000002fJqwMAE",
      "SfItemIdRef": "",
      "ProcessingDate": "14-10-2026",
      "ProcessingTime": "22:55:21",
      "Field": ""
    }
  ]
}
```

### ไม่สำเร็จ: HTTP 400

ข้อความมาจากการทดสอบจริง ส่วนค่าอื่นเป็นตัวอย่าง

```json
{
  "RequestId": "20261014_114329_114331",
  "Status": "E",
  "Orders": [
    {
      "Status": "E",
      "Code": "ZSDE002/251",
      "Message": "Plant 9999 does not exist",
      "SalesOrderNumber": "",
      "DocumentType": "CCIS",
      "CustomerReference": "b8MAz000002fJqwMAE",
      "SfHeaderIdRef": "b8MAz000002fJqwMAE",
      "SfItemIdRef": "a2GAz000000mAmhMAE",
      "ProcessingDate": "14-10-2026",
      "ProcessingTime": "22:50:00",
      "Field": "Plant"
    }
  ]
}
```

### สำเร็จบางส่วน: HTTP 200

ตัวอย่างตามโครงสร้างในโค้ด ไม่ใช่ response จริง

```json
{
  "RequestId": "20261014_114329_114331",
  "Status": "W",
  "Orders": [
    {
      "Status": "S",
      "Code": "ZSDE002/500",
      "Message": "Document O250000040 created",
      "SalesOrderNumber": "O250000040",
      "DocumentType": "CCIS",
      "CustomerReference": "REF-A",
      "SfHeaderIdRef": "SF-A",
      "SfItemIdRef": "",
      "ProcessingDate": "14-10-2026",
      "ProcessingTime": "22:50:00",
      "Field": ""
    },
    {
      "Status": "E",
      "Code": "ZSDE002/251",
      "Message": "Plant 9999 does not exist",
      "SalesOrderNumber": "",
      "DocumentType": "CCIS",
      "CustomerReference": "REF-B",
      "SfHeaderIdRef": "SF-B",
      "SfItemIdRef": "SF-ITEM-B1",
      "ProcessingDate": "14-10-2026",
      "ProcessingTime": "22:50:00",
      "Field": "Plant"
    }
  ]
}
```

## Field บังคับใน request

| ระดับ | บังคับเสมอ | บังคับตามเงื่อนไข |
|---|---|---|
| Header | `SfHeaderIdRef`, `SalesOrderTempId`, `ProcessType`, `TranType`, `SalesOrderType`, `SalesOrganization`, `DistributionChannel`, `Division`, `SoldToParty`, `ShipToParty`, `BillToParty`, `Payer`, `CustomerReference`, `DocumentDate`, `ShippingConditions` | `StockVan`, `PaymentTransactionReference`, `TaxDocumentNo`, `OrderReason`, `OrderReasonText` |
| Item | ไม่มี | `MaterialNumber` (เมื่อไม่ส่ง `CustomerMaterial`), `StorageLocation`, `Batch`, `SfItemIdRef` |

เงื่อนไขส่วนใหญ่กำหนดจาก `ZTBC_PARAM` ตาม process type หรือ tran type

## ข้อควรรู้สำหรับฝั่ง SBPA

- HTTP 400 ไม่ได้แปลว่าระบบล้ม กรณีนี้ body ยังเป็น JSON ที่มีเหตุผลราย order ควรอ่าน body ด้วย
- HTTP 200 ไม่ได้แปลว่าสำเร็จทุก order ต้องเช็ค `Status` ระดับบนสุดด้วย
- `Orders` ใน response เป็นรายการข้อความ หนึ่ง order อาจมีหลายแถว และไม่มี `SalesOrderTempId` กลับไป จึงต้องจับคู่ด้วย `SfHeaderIdRef` หรือ `CustomerReference`
- ชื่อ field ต้องเป็น PascalCase ตรงตัว ถ้าพิมพ์ผิดจะถูกละเลยโดยไม่มี error
- `RequestId` ไม่บังคับ ถ้าไม่ส่ง ระบบสร้างให้เป็น `YYYYMMDD_HHMMSS` ตามเวลา local
- รูปแบบวันที่ที่รับ: `2026-10-10`, `2026/10/10`, `2026.10.10` หรือ `20261010`
- `ProcessingDate` และ `ProcessingTime` เป็นเวลา local ตาม param ปัจจุบันคือ UTC+7

## ยังไม่ได้ยืนยัน

โค้ดของ ZSDE002 ไม่ได้ตรวจ CSRF token แต่ยังไม่ได้ตรวจว่า request ที่ทดสอบผ่านใน Postman ส่ง header อะไรไปบ้าง ควรเทียบกับ request จริงของฝั่ง SBPA
