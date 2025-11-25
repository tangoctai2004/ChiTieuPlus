# Kịch Bản Thuyết Trình Báo Cáo Thực Tập
**Đề tài:** Xây dựng ứng dụng quản lý chi tiêu cá nhân (Chi Tiêu+) trên nền tảng iOS
**Sinh viên thực hiện:** Tạ Ngọc Tài
**GVHD:** ThS. Nguyễn Văn Tiến
**Thời lượng dự kiến:** 10-12 phút

---

## Slide 1: Chào hỏi & Giới thiệu
**(Thời gian: 30s)**

*   **Hành động:** Đứng nghiêm túc, mỉm cười, nhìn về phía hội đồng/GVHD.
*   **Lời thoại:**
    > "Lời đầu tiên, em xin gửi lời chào trân trọng đến Thầy Nguyễn Văn Tiến cùng các thầy cô và các bạn đang có mặt trong buổi báo cáo ngày hôm nay.
    >
    > Em tên là Tạ Ngọc Tài. Hôm nay, em xin phép được trình bày báo cáo thực tập cơ sở của mình với đề tài: **'Xây dựng ứng dụng quản lý chi tiêu cá nhân - Chi Tiêu+'** trên nền tảng iOS."

---

## Slide 2: Tổng Quan Đề Tài (Vấn đề & Giải pháp)
**(Thời gian: 1 phút 30s)**

*   **Hành động:** Chỉ tay vào phần "Vấn đề thực tế" bên trái, sau đó chuyển sang phần "Giải pháp" bên phải.
*   **Lời thoại:**
    > "Xuất phát từ thực tế cuộc sống, trong bối cảnh kinh tế số hiện nay, việc quản lý tài chính cá nhân đang trở nên phức tạp hơn bao giờ hết.
    >
    > Nhiều người trẻ, trong đó có cả sinh viên chúng ta, thường gặp phải vấn đề **'thiếu kiểm soát'** dòng tiền. Chúng ta không biết tiền của mình đi đâu về đâu, dẫn đến tình trạng 'cháy túi' vào cuối tháng. Các phương pháp ghi chép thủ công bằng sổ tay hay Excel thì lại quá tốn thời gian và khó tra cứu.
    >
    > Để giải quyết bài toán này, em đã phát triển **Chi Tiêu+**. Đây không chỉ là một công cụ ghi chép đơn thuần, mà là một trợ lý tài chính thông minh trên điện thoại.
    >
    > Mục tiêu của ứng dụng là **'All-in-One'**: Tích hợp ghi chép, lập ngân sách và báo cáo trong một nơi duy nhất. Đặc biệt, em tập trung tối ưu hóa trải nghiệm người dùng (UX) để thao tác nhập liệu cực nhanh, chỉ mất dưới 3 giây cho một giao dịch, giúp người dùng hình thành thói quen quản lý tài chính chủ động."

---

## Slide 3: Công Nghệ Sử Dụng (Tech Stack)
**(Thời gian: 1 phút)**

*   **Hành động:** Lần lượt chỉ vào các logo công nghệ khi nhắc đến tên của chúng.
*   **Lời thoại:**
    > "Để xây dựng ứng dụng này, em đã sử dụng các công nghệ hiện đại nhất trong hệ sinh thái phát triển của Apple:
    >
    > *   Đầu tiên là ngôn ngữ **Swift 5.9**: Với ưu điểm an toàn, hiệu năng cao và cú pháp hiện đại.
    > *   Về giao diện, em sử dụng **SwiftUI**: Đây là framework mới giúp xây dựng giao diện người dùng một cách trực quan và mượt mà.
    > *   Để lưu trữ dữ liệu offline, em chọn **Core Data**: Giúp quản lý cơ sở dữ liệu bền vững và hiệu quả ngay trên thiết bị người dùng.
    > *   Và cuối cùng, toàn bộ dự án được tổ chức theo kiến trúc **MVVM (Model-View-ViewModel)** để đảm bảo mã nguồn rõ ràng, dễ bảo trì và mở rộng."

---

## Slide 4: Kiến Trúc Hệ Thống (MVVM Pattern)
**(Thời gian: 1 phút 30s)**

*   **Hành động:** Chỉ vào sơ đồ bên trái để giải thích các thành phần, sau đó chỉ sang quy trình luồng dữ liệu bên phải.
*   **Lời thoại:**
    > "Đi sâu hơn vào kiến trúc hệ thống, em xin trình bày về mô hình MVVM mà ứng dụng đang áp dụng.
    >
    > Như thầy cô thấy trên sơ đồ:
    > *   **View (SwiftUI):** Là nơi hiển thị giao diện và nhận tương tác từ người dùng.
    > *   **ViewModel:** Đóng vai trò trung gian, chứa các logic xử lý nghiệp vụ.
    > *   **Model (Core Data):** Là nơi lưu trữ dữ liệu thực tế.
    >
    > **Luồng dữ liệu (Data Flow) hoạt động như sau:**
    > 1.  Khi người dùng thực hiện một hành động (ví dụ: nhấn nút 'Thêm'), View sẽ gửi một yêu cầu (Intent) đến ViewModel.
    > 2.  ViewModel sẽ tiếp nhận, kiểm tra tính hợp lệ của dữ liệu, tính toán logic, và sau đó tương tác với Model để lưu xuống cơ sở dữ liệu.
    > 3.  Sau khi xử lý xong, ViewModel sẽ cập nhật trạng thái. Nhờ cơ chế Binding của SwiftUI, giao diện (View) sẽ tự động được vẽ lại để hiển thị dữ liệu mới nhất cho người dùng mà không cần reload thủ công."

---

## Slide 5: Cơ Sở Dữ Liệu (Schema Design)
**(Thời gian: 1 phút)**

*   **Hành động:** Chỉ vào sơ đồ ERD bên phải.
*   **Lời thoại:**
    > "Về thiết kế cơ sở dữ liệu, em đã xây dựng 4 thực thể chính xoay quanh nghiệp vụ tài chính:
    >
    > 1.  **Category (Danh mục):** Quản lý các nhóm thu chi (như Ăn uống, Di chuyển...).
    > 2.  **Transaction (Giao dịch):** Là bảng dữ liệu quan trọng nhất, lưu trữ chi tiết từng khoản thu/chi.
    > 3.  **Budget (Ngân sách):** Để thiết lập giới hạn chi tiêu.
    > 4.  **SavingsGoal (Tiết kiệm):** Để quản lý các mục tiêu tích lũy.
    >
    > Mối quan hệ quan trọng nhất ở đây là **One-to-Many** giữa Category và Transaction. Một danh mục sẽ chứa nhiều giao dịch, giúp chúng ta dễ dàng thống kê xem mình đã tiêu bao nhiêu tiền cho việc ăn uống hay mua sắm trong tháng."

---

## Slide 6: Quản Lý Thu Chi (Demo Tính Năng 1)
**(Thời gian: 1 phút)**

*   **Hành động:** Chỉ vào 3 màn hình điện thoại từ trái sang phải.
*   **Lời thoại:**
    > "Tiếp theo, em xin đi vào các chức năng chính của ứng dụng.
    >
    > Đây là luồng người dùng cơ bản nhất: **Quản lý thu chi**.
    > *   Đầu tiên là màn hình **Khởi động (Splash)**: Tải dữ liệu nền nhanh chóng.
    > *   Tiếp đến là **Trang chủ (Home)**: Nơi người dùng có cái nhìn tổng quan về số dư và các giao dịch gần nhất.
    > *   Và quan trọng nhất là màn hình **Thêm giao dịch**: Em thiết kế form nhập liệu cực kỳ tối giản. Người dùng chỉ cần chọn danh mục, nhập số tiền và nhấn Lưu. Mọi thứ diễn ra chưa đến 3 giây."

---

## Slide 7: Quản Lý Danh Mục & Dữ Liệu (Demo Tính Năng 2)
**(Thời gian: 1 phút)**

*   **Hành động:** Chỉ vào danh sách danh mục và màn hình chỉnh sửa.
*   **Lời thoại:**
    > "Để cá nhân hóa trải nghiệm, Chi Tiêu+ cho phép người dùng tùy chỉnh mạnh mẽ.
    >
    > Người dùng có thể tự tạo **Danh mục mới** với hàng trăm icon và màu sắc tùy chọn để phù hợp với sở thích cá nhân.
    > Ngoài ra, ứng dụng cũng hỗ trợ đầy đủ các thao tác **Chỉnh sửa và Xóa** giao dịch, giúp người dùng dễ dàng sửa chữa sai sót trong quá trình nhập liệu."

---

## Slide 8: Báo Cáo & Ngân Sách (Demo Tính Năng 3)
**(Thời gian: 1 phút)**

*   **Hành động:** Nhấn mạnh vào 2 biểu đồ (Tròn và Cột).
*   **Lời thoại:**
    > "Giá trị cốt lõi của ứng dụng nằm ở khả năng **Phân tích tài chính**.
    >
    > *   **Biểu đồ Donut (Tròn):** Giúp người dùng thấy ngay tỷ trọng chi tiêu (Ví dụ: 50% cho ăn uống, 30% cho nhà ở...).
    > *   **Biểu đồ Bar (Cột):** Giúp so sánh chi tiêu giữa các ngày hoặc các tháng, từ đó nhận ra xu hướng tiêu dùng của bản thân.
    >
    > Bên cạnh đó là tính năng **Cảnh báo ngân sách**, hệ thống sẽ tự động nhắc nhở khi người dùng chi tiêu vượt quá hạn mức đã đặt ra."

---

## Slide 9: Cài Đặt & Tiện Ích (Demo Tính Năng 4)
**(Thời gian: 45s)**

*   **Hành động:** Chỉ vào màn hình Dark Mode.
*   **Lời thoại:**
    > "Cuối cùng là các tiện ích nâng cao trải nghiệm.
    >
    > Ứng dụng hỗ trợ hoàn hảo chế độ **Dark Mode (Giao diện tối)**, không chỉ đẹp mắt, hiện đại mà còn giúp bảo vệ mắt khi sử dụng vào ban đêm.
    > Tính năng **Nhắc nhở thông minh** cũng được tích hợp để gửi thông báo nhắc người dùng ghi chép chi tiêu vào một khung giờ cố định mỗi ngày."

---

## Slide 10: Kết Quả & Hướng Phát Triển
**(Thời gian: 1 phút)**

*   **Hành động:** Tổng kết lại các ý chính trên slide.
*   **Lời thoại:**
    > "Tổng kết lại, qua quá trình thực tập và phát triển dự án, em đã đạt được những kết quả sau:
    > *   Hoàn thiện một ứng dụng iOS hoàn chỉnh với đầy đủ tính năng quản lý tài chính cơ bản.
    > *   Áp dụng thành công kiến trúc MVVM và Core Data vào dự án thực tế.
    > *   Xây dựng được giao diện hiện đại, hỗ trợ Dark Mode và trải nghiệm mượt mà.
    >
    > Tuy nhiên, ứng dụng vẫn còn nhiều dư địa để phát triển. Trong tương lai, em dự định sẽ bổ sung thêm:
    > *   Tính năng **Cloud Sync** để đồng bộ dữ liệu qua iCloud.
    > *   Tích hợp **AI** để phân tích thói quen và đưa ra lời khuyên tài chính thông minh hơn."

---

## Slide 11: Thank You (Kết thúc)
**(Thời gian: 30s)**

*   **Hành động:** Cúi chào và mỉm cười.
*   **Lời thoại:**
    > "Bài báo cáo của em đến đây là kết thúc.
    >
    > Em xin chân thành cảm ơn Thầy Nguyễn Văn Tiến đã tận tình hướng dẫn, cũng như quý thầy cô và các bạn đã lắng nghe.
    >
    > Em rất mong nhận được những ý kiến đóng góp và câu hỏi từ hội đồng để hoàn thiện sản phẩm tốt hơn ạ. Em xin cảm ơn!"

---
