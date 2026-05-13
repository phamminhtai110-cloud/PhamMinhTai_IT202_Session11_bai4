-- =====================================================
-- [PHÂN TÍCH] TRA CỨU CÔNG NỢ LINH HOẠT
-- =====================================================

-- =====================================================
-- PHẦN A: PHÂN TÍCH & ĐỀ XUẤT
-- =====================================================

-- =====================================================
-- 1. ĐỊNH NGHĨA INPUT / OUTPUT
-- =====================================================

-- INPUT:
-- p_patient_id : Mã bệnh nhân
-- p_phone      : Số điện thoại

-- OUTPUT:
-- p_total_due  : Tổng công nợ
-- p_message    : Thông báo trạng thái

-- =====================================================
-- LOẠI THAM SỐ
-- =====================================================

-- IN:
-- Nhận dữ liệu tra cứu từ frontend

-- OUT:
-- Trả kết quả công nợ + trạng thái xử lý

-- =====================================================
-- 2. ĐỀ XUẤT 2 GIẢI PHÁP
-- =====================================================

-- =====================================================
-- GIẢI PHÁP 1: IF / ELSEIF
-- =====================================================

-- Ý tưởng:
-- Kiểm tra lần lượt:
--   - Nếu có ID -> tìm theo ID
--   - Else nếu có Phone -> tìm theo Phone
--   - Else -> báo lỗi

-- Ví dụ:
-- IF p_patient_id IS NOT NULL THEN
--     ...
-- ELSEIF p_phone IS NOT NULL THEN
--     ...
-- END IF;

-- =====================================================
-- GIẢI PHÁP 2: TRUY VẤN LINH HOẠT
-- =====================================================

-- Ý tưởng:
-- Viết 1 SELECT duy nhất với điều kiện OR:

-- WHERE
--    (patient_id = p_patient_id OR p_patient_id IS NULL)
-- AND
--    (phone = p_phone OR p_phone IS NULL)

-- Procedure tự thích nghi với dữ liệu đầu vào.

-- =====================================================
-- 3. SO SÁNH 2 GIẢI PHÁP
-- =====================================================

-- +----------------------+----------------------+----------------------+
-- | TIÊU CHÍ             | IF / ELSEIF          | WHERE LINH HOẠT      |
-- +----------------------+----------------------+----------------------+
-- | Dễ đọc               | Cao                  | Trung bình           |
-- | Dễ debug             | Cao                  | Khó hơn              |
-- | Tối ưu hiệu năng     | Tốt                  | Có thể chậm hơn      |
-- | Linh hoạt            | Trung bình           | Cao                  |
-- | Dễ mở rộng logic     | Cao                  | Trung bình           |
-- +----------------------+----------------------+----------------------+

-- =====================================================
-- 4. GIẢI PHÁP ĐƯỢC CHỌN
-- =====================================================

-- Chọn IF / ELSEIF vì:
-- - Dễ đọc
-- - Dễ kiểm soát lỗi
-- - Phù hợp bài toán nghiệp vụ
-- - Dễ bảo trì cho Backend Team

-- =====================================================
-- PHẦN B: THIẾT KẾ & TRIỂN KHAI
-- =====================================================

-- =====================================================
-- 1. THIẾT KẾ LUỒNG XỬ LÝ
-- =====================================================

-- Bước 1:
-- Kiểm tra cả ID và Phone đều NULL?
-- -> Báo lỗi ngay

-- Bước 2:
-- Nếu có ID:
-- -> Tra cứu theo ID

-- Bước 3:
-- Nếu không có ID nhưng có Phone:
-- -> Tra cứu theo Phone

-- Bước 4:
-- Nếu không tìm thấy:
-- -> total_due = 0
-- -> báo không tìm thấy

-- Bước 5:
-- Nếu tìm thấy:
-- -> trả tổng nợ
-- -> báo thành công

-- =====================================================
-- 2. TRIỂN KHAI PROCEDURE
-- =====================================================

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

    -- =========================================
    -- TRƯỜNG HỢP NULL CẢ 2
    -- =========================================

    IF p_patient_id IS NULL
       AND p_phone IS NULL THEN

        SET p_total_due = 0;
        SET p_message = 'Loi: Phai nhap ID hoac Phone';

    ELSE

        -- =====================================
        -- TRA CỨU THEO ID
        -- =====================================

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

        -- =====================================
        -- TRA CỨU THEO PHONE
        -- =====================================

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

-- =====================================================
-- PHẦN C: NGHIỆM THU
-- =====================================================

-- =====================================================
-- TEST 1: CHỈ TRUYỀN ID
-- =====================================================

CALL GetPatientDebt(
    1,
    NULL,
    @total_due,
    @message
);

SELECT @total_due AS total_due,
       @message AS message;

-- Kết quả mong muốn:
-- total_due = 1500000
-- message = 'Tra cuu thanh cong'

-- =====================================================
-- TEST 2: CHỈ TRUYỀN PHONE
-- =====================================================

CALL GetPatientDebt(
    NULL,
    '0912222333',
    @total_due,
    @message
);

SELECT @total_due AS total_due,
       @message AS message;

-- Kết quả mong muốn:
-- total_due = 0
-- message = 'Tra cuu thanh cong'

-- =====================================================
-- TEST 3: NULL CẢ 2
-- =====================================================

CALL GetPatientDebt(
    NULL,
    NULL,
    @total_due,
    @message
);

SELECT @total_due AS total_due,
       @message AS message;

-- Kết quả mong muốn:
-- total_due = 0
-- message = 'Loi: Phai nhap ID hoac Phone'

-- =====================================================
-- TEST 4: DỮ LIỆU KHÔNG TỒN TẠI
-- =====================================================

CALL GetPatientDebt(
    999,
    NULL,
    @total_due,
    @message
);

SELECT @total_due AS total_due,
       @message AS message;

-- Kết quả mong muốn:
-- total_due = 0
-- message = 'Khong tim thay benh nhan'