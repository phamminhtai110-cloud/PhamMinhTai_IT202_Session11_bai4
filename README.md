# PhamMinhTai_IT202_Session11_bai4

# BÁO CÁO PHÂN TÍCH HỆ THỐNG

## Bài 4 - Tra cứu công nợ linh hoạt

---

# 1. Mô tả bài toán

Tại khu vực tiếp tân của phòng khám, nhân viên thường xuyên cần tra cứu công nợ của bệnh nhân.

Trong thực tế:

* Có người nhớ Mã bệnh nhân (Patient_ID)
* Có người chỉ nhớ Số điện thoại (Phone)
* Có trường hợp nhập cả 2 thông tin

Tech Lead yêu cầu xây dựng đúng một Stored Procedure duy nhất có khả năng tra cứu linh hoạt.

Procedure cần:

* Tra cứu theo ID
* Hoặc tra cứu theo Phone
* Hoặc nhận cả 2

Ngoài ra hệ thống phải xử lý an toàn các tình huống lỗi.

---

# 2. Quy tắc nghiệp vụ

## Input

* Patient_ID
* Phone

## Output

* Tổng công nợ
* Thông báo trạng thái

---

## Các tình huống đặc biệt

### Trường hợp 1

Người dùng bỏ trống cả ID và Phone.

Hệ thống phải:

* Không truy vấn toàn bộ database
* Chặn ngay lập tức
* Báo lỗi

---

### Trường hợp 2

ID hoặc Phone không tồn tại.

Hệ thống phải:

* Trả công nợ = 0
* Báo không tìm thấy

---

# 3. Phân tích Input / Output

## 3.1 Input Parameters

| Tham số      | Ý nghĩa       |
| ------------ | ------------- |
| p_patient_id | Mã bệnh nhân  |
| p_phone      | Số điện thoại |

---

## 3.2 Output Parameters

| Tham số     | Ý nghĩa          |
| ----------- | ---------------- |
| p_total_due | Tổng công nợ     |
| p_message   | Trạng thái xử lý |

---

# 4. Phân tích loại tham số

## IN Parameters

Dùng để:

* Nhận dữ liệu tìm kiếm từ Frontend
* Truyền điều kiện tra cứu

```sql
IN p_patient_id
IN p_phone
```

---

## OUT Parameters

Dùng để:

* Trả kết quả công nợ
* Trả thông báo trạng thái

```sql
OUT p_total_due
OUT p_message
```

---

# 5. Đề xuất giải pháp

# Giải pháp 1 - IF / ELSEIF

## Ý tưởng

Kiểm tra lần lượt:

* Nếu có ID → tìm theo ID
* Nếu không có ID nhưng có Phone → tìm theo Phone
* Nếu cả 2 NULL → báo lỗi

---

## Ví dụ logic

```sql
IF p_patient_id IS NOT NULL THEN
    ...
ELSEIF p_phone IS NOT NULL THEN
    ...
END IF;
```

---

# Giải pháp 2 - WHERE linh hoạt

## Ý tưởng

Sử dụng một câu SELECT duy nhất:

```sql
WHERE
   (patient_id = p_patient_id OR p_patient_id IS NULL)
AND
   (phone = p_phone OR p_phone IS NULL)
```

Query tự thích ứng với dữ liệu đầu vào.

---

# 6. So sánh 2 giải pháp

| Tiêu chí         | IF / ELSEIF | WHERE linh hoạt |
| ---------------- | ----------- | --------------- |
| Dễ đọc           | Cao         | Trung bình      |
| Dễ debug         | Cao         | Trung bình      |
| Dễ mở rộng       | Cao         | Trung bình      |
| Hiệu năng        | Tốt         | Có thể thấp hơn |
| Linh hoạt        | Trung bình  | Cao             |
| Phù hợp bài toán | Cao         | Trung bình      |

---

# 7. Giải pháp được lựa chọn

## Chọn IF / ELSEIF

Lý do:

* Logic rõ ràng
* Dễ bảo trì
* Dễ kiểm soát lỗi
* Phù hợp môi trường nghiệp vụ thực tế
* Tối ưu cho đội Backend và DBA

---

# 8. Thiết kế luồng xử lý

## Bước 1

Kiểm tra:

```sql
p_patient_id IS NULL
AND p_phone IS NULL
```

Nếu đúng:

* Chặn truy vấn
* Báo lỗi

---

## Bước 2

Nếu có ID:

* Tra cứu theo ID

---

## Bước 3

Nếu không có ID nhưng có Phone:

* Tra cứu theo Phone

---

## Bước 4

Nếu không tìm thấy:

* total_due = 0
* Báo không tìm thấy

---

## Bước 5

Nếu tìm thấy:

* Trả tổng công nợ
* Trả thông báo thành công

---

# 9. Procedure triển khai

```sql
DROP PROCEDURE IF EXISTS GetPatientDebt;

DELIMITER //

CREATE PROCEDURE GetPatientDebt(

    IN p_patient_id INT,
    IN p_phone VARCHAR(15),

    OUT p_total_due DECIMAL(18,2),
    OUT p_message VARCHAR(255)

)
BEGIN

    DECLARE v_count INT DEFAULT 0;

    IF p_patient_id IS NULL
       AND p_phone IS NULL THEN

        SET p_total_due = 0;
        SET p_message = 'Loi: Phai nhap ID hoac Phone';

    ELSE

        IF p_patient_id IS NOT NULL THEN

            SELECT COUNT(*)
            INTO v_count
            FROM Patient_Invoices
            WHERE patient_id = p_patient_id;

            IF v_count > 0 THEN

                SELECT total_due
                INTO p_total_due
                FROM Patient_Invoices
                WHERE patient_id = p_patient_id;

                SET p_message = 'Tra cuu thanh cong';

            ELSE

                SET p_total_due = 0;
                SET p_message = 'Khong tim thay benh nhan';

            END IF;

        ELSE

            SELECT COUNT(*)
            INTO v_count
            FROM Patients p
            JOIN Patient_Invoices pi
                 ON p.patient_id = pi.patient_id
            WHERE p.phone = p_phone;

            IF v_count > 0 THEN

                SELECT pi.total_due
                INTO p_total_due
                FROM Patients p
                JOIN Patient_Invoices pi
                     ON p.patient_id = pi.patient_id
                WHERE p.phone = p_phone;

                SET p_message = 'Tra cuu thanh cong';

            ELSE

                SET p_total_due = 0;
                SET p_message = 'Khong tim thay benh nhan';

            END IF;

        END IF;

    END IF;

END //

DELIMITER ;
```

---

# 10. Giải thích logic hoạt động

## 10.1 Chặn NULL toàn bộ

```sql
IF p_patient_id IS NULL
AND p_phone IS NULL
```

Mục tiêu:

* Tránh quét toàn bộ database
* Bảo vệ hiệu năng server
* Ngăn lỗi từ frontend

---

## 10.2 Tra cứu theo ID

Nếu có Patient_ID:

* Kiểm tra tồn tại
* Nếu có → lấy total_due
* Nếu không → báo không tìm thấy

---

## 10.3 Tra cứu theo Phone

Nếu chỉ có Phone:

* JOIN Patients + Patient_Invoices
* Lấy công nợ tương ứng

---

# 11. Kiểm thử hệ thống

## 11.1 Test chỉ truyền ID

### Input

```sql
CALL GetPatientDebt(
    1,
    NULL,
    @total_due,
    @message
);
```

### Kết quả mong muốn

| total_due | message            |
| --------- | ------------------ |
| 1500000   | Tra cuu thanh cong |

---

## 11.2 Test chỉ truyền Phone

### Input

```sql
CALL GetPatientDebt(
    NULL,
    '0912222333',
    @total_due,
    @message
);
```

### Kết quả mong muốn

| total_due | message            |
| --------- | ------------------ |
| 0         | Tra cuu thanh cong |

---

## 11.3 Test NULL cả 2

### Input

```sql
CALL GetPatientDebt(
    NULL,
    NULL,
    @total_due,
    @message
);
```

### Kết quả mong muốn

| total_due | message                      |
| --------- | ---------------------------- |
| 0         | Loi: Phai nhap ID hoac Phone |

---

## 11.4 Test dữ liệu không tồn tại

### Input

```sql
CALL GetPatientDebt(
    999,
    NULL,
    @total_due,
    @message
);
```

### Kết quả mong muốn

| total_due | message                  |
| --------- | ------------------------ |
| 0         | Khong tim thay benh nhan |

---

# 12. Kết luận

Việc xây dựng Stored Procedure tra cứu linh hoạt giúp:

* Giảm số lượng API backend
* Tăng khả năng tái sử dụng logic
* Tăng hiệu năng xử lý nghiệp vụ
* Chuẩn hóa dữ liệu trả về
* Giảm lỗi frontend

Hệ thống sau khi triển khai:

* Hỗ trợ nhiều kiểu tìm kiếm
* Chặn truy vấn nguy hiểm
* Đảm bảo an toàn dữ liệu
* Tăng trải nghiệm người dùng

---

# 13. Tổng kết kỹ thuật

| Thành phần       | Nội dung                    |
| ---------------- | --------------------------- |
| Loại bài toán    | Flexible Query Procedure    |
| Kỹ thuật chính   | Stored Procedure            |
| Kiểu tham số     | IN + OUT                    |
| Logic xử lý      | IF / ELSEIF                 |
| Kỹ thuật JOIN    | Patients + Patient_Invoices |
| Kiểm tra dữ liệu | NULL Validation             |
| Giá trị hệ thống | Linh hoạt + An toàn         |
