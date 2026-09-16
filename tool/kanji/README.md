## Quy tắc hiện hành — thống kê v4 / taxonomy v3 / cây v2 (2026-09-17)

- Chỉ có `radical`, `kanji`, `supplementary`. Tra bộ thủ theo `display_form → source_element → source_original`, trước kiểm tra Jōyō. Nguồn nhận dạng là `radicals.tsv` và ánh xạ sản phẩm `⺍ → 小`; không dùng các biến thể suy ra trong cache làm đầu vào nhận dạng.
- Jōyō lấy từ KANJIDIC2 đã khóa checksum: lớp 1–6, 8, đúng 2.136 chữ. Tầng không phải bộ thủ/Jōyō được bỏ và đưa con lên; lá không nhận dạng được là Nét phụ. `partial` chỉ còn metadata nguồn `source_partial`, không phải loại đầu ra.
- `display_form` luôn là dạng SVG. Bộ thủ có `radical_id`, tên/nghĩa và catalog gốc liên kết riêng. Ví dụ `孝 → 耂 Lão + 子 Tử`, `座 → 广 + 人 + 人 + 土`; hai 人 chọn độc lập. Liên kết “Chi tiết bộ thủ” giữ nguyên biến thể khi tra chữ liên quan.
- Các generator cũ đều chuyển tới `build_taxonomy.py`. Cây UI sinh từ SVG gốc và dừng tại bộ thủ; occurrences vẫn là các lá của cây. Phép chiếu thống kê riêng duyệt cả bộ cha/con, giữ từng vị trí cấu tạo, nhưng bỏ wrapper khi bộ, dạng và toàn bộ nét trùng nhau. Vì vậy `員 → 口 + 貝 + 目 + 八`, còn cây UI của `員` vẫn chỉ hiện `口 + 貝`.
- `202609170001_kanji_radical_statistics_v4.sql` dựng lại dữ liệu feature Kanji trong transaction, chặn FK từ bảng ngoài phạm vi và chỉ xóa snapshot thống kê Kanji. Bảng nội bộ `kanji_radical_stat_components` không cấp quyền đọc client; `kanji_components` giữ quan hệ tại điểm dừng để danh sách Hán tự liên quan không đổi.
- Cache: `kanji.catalog.v3.`, `kanji.tree.v2.`, `kanji.snapshot.v4.{userId}`. Không đọc lại snapshot cũ; giữ cache SVG theo commit vì nét gốc không đổi. Nội dung mới cần tải online ít nhất một lần.
- Số liệu sinh thực tế: 10.495 node UI (6.050 Bộ thủ, 3.047 Hán tự, 1.398 Nét phụ), 7.448 occurrences v3, 5.823 quan hệ UI và 7.659 quan hệ thống kê v4. Đây là kết quả, không phải quota kiểm thử; invariant là phân loại đúng nguồn và phân hoạch nét đầy đủ, không trùng.

```powershell
python tool/kanji/build_taxonomy.py --cache-only
python -m unittest discover -s tool/kanji -p "test_*.py"
node tool/kanji/test_database.mjs --assertions-only
flutter analyze
flutter test --dart-define=KANJI_CORPUS=true --dart-define=KANJI_CAPTURE=true
flutter build web --release
```

Mặc định generator ghi migration **mới v4**, không ghi lại các migration lịch sử. Sau khi triển khai v4, những thay đổi dữ liệu tiếp theo phải dùng tên migration mới. `--validate-only` không ghi kết quả; `--cache-only` chuẩn bị cache và báo cáo, không ghi migration.

Harness kiểm cả lịch sử migration và rebuild, so sánh toàn bộ nội dung 6 bảng từ vựng/thư mục/SRS/cài đặt học/thiết bị/tài khoản trước-sau, cùng RLS, lỗi rollback và đếm 人 trong 座. Cloud kiểm chỉ đọc bằng `verify_learning_preservation.sql` và `verify_taxonomy_cloud.sql`; không chạy fixtures chứa tài khoản giả lên cloud.

Các phần phía dưới là lịch sử triển khai, không phải quy tắc taxonomy hiện hành.

Nghiệm thu v3: 180 Flutter tests qua khi bật corpus/capture; 16 Python tests qua; analyzer sạch và database harness qua. Đã áp dụng migration v3 lên Supabase, truy vấn cloud xác nhận 2.136 cây v2, 7.448 occurrences v3, 0 `partial`, 0 node Hán tự ngoài Jōyō và 0 lỗi phân hoạch. Fingerprint trước/sau khớp toàn bộ 1.026 từ, 24 thư mục, 1.026 SRS, cài đặt học/thiết bị và tài khoản; không gọi RPC cập nhật thống kê. Client chưa được phát hành.

Web release JavaScript đã build thành công. Còn cảnh báo dry-run Wasm của `flutter_tts` và font Cupertino đã có trước; không coi đây là nghiệm thu Wasm hoặc ứng dụng Android/iOS. Ảnh `build/kanji_qa/tree_05b5d_dark_paths.png` xác nhận 耂 Lão và thông tin/link giữ biến thể; ảnh `tree_05ea7_light_paths_human.png` xác nhận chọn riêng từng 人.

## Lịch sử: phân tích nhiều tầng — 2026-09-08

- `kanji_decompositions` bổ sung 2.136 cây / 11.151 nút, sinh từ cùng commit KanjiVG. Dữ liệu v2, các quan hệ bộ thủ và snapshot thống kê không đổi. Đã áp dụng migrations `202609080001–002` lên Supabase; truy vấn chỉ đọc xác nhận 0 lỗi phân hoạch nét và quyền catalog chỉ đọc cho authenticated.
- Mặc định hiện thành phần lớn: `想 → 相 + 心`, `森 → 木 + 林`, `機 → 木 + 幾`. Bấm Hán tự mở thêm một tầng ngay bên dưới và tô đỏ đúng ID nét trong SVG chữ gốc; bộ thủ là điểm dừng, các lần xuất hiện giống nhau có ID riêng. Nhóm `partial` hiển thị hình nét với chú thích một phần; không giả làm Hán tự đầy đủ.
- Cây và nghĩa tải theo lô vào cache riêng `kanji.tree.v1.` (1 MiB/200 mục), mở sâu không gọi mạng. Thiếu mục từ vẫn mở cấu tạo được. Thiếu/lệch SVG vẫn xem cây nhưng không đoán nét. Thiếu cây dùng UI phân tích cơ bản v2 và nút thử lại.
- Ô Hán tự màu chàm, bộ thủ xanh ngọc, nét phụ trung tính; nhãn loại, dấu chọn và viền đỏ phân biệt trạng thái. Hình thường 200 px, 144 px dưới 600 px chiều cao cửa sổ. Hình/điều khiển cố định trên vùng nội dung cuộn; nếu phần dialog còn dưới 450 px hoặc chữ lớn hơn 150%, chuyển sang cuộn chung để không che hết nội dung. Mở nhánh tôn trọng giảm chuyển động.
- `KanjiDecompositionSelection` quản lý nhánh và nút chọn riêng với animator. `asOccurrence` chỉ tái sử dụng hợp đồng ID nét của renderer v2, không ghi dữ liệu occurrences hoặc thống kê.

Kiểm tra/sinh dữ liệu:

```powershell
python tool/kanji/build_decompositions.py --cache-only
python tool/kanji/build_decompositions.py --validate-only
python tool/kanji/test_decompositions.py
python tool/kanji/test_components.py
node tool/kanji/test_database.mjs --assertions-only
flutter analyze
flutter test --dart-define=KANJI_CORPUS=true --dart-define=KANJI_CAPTURE=true
flutter build web --release
```

Không chạy generator ở chế độ ghi seed mặc định để sửa migrations đã triển khai. Thay đổi cây trong tương lai phải có migration mới và đối chiếu nguồn/ngoại lệ; không tự đổi checksum hoặc quy tắc thống kê. SHA-256 của corpus JSON chuẩn hóa hiện tại: `7683c12f6fabd8adb1a50e3648da45adb06fd1d1752e6c23346067a5f50d4cb4`.

Kết quả: analyzer sạch, 177 Flutter tests qua (bao gồm corpus và capture), 6 Python hierarchy tests + 8 v2 tests qua, database harness qua và xác nhận nguyên vẹn occurrences/quan hệ/snapshot trước-sau migration. 28 ảnh cây thật trong `build/kanji_qa/tree_*.png`, gồm sáng/tối và SVG dự phòng; đã rà hình, tô nét và font Kanji trong nhãn hỗn hợp. Web release JavaScript build thành công; còn các cảnh báo Wasm `flutter_tts` và font Cupertino đã có trước. Chưa phát hành client web; chưa kiểm thử ứng dụng native trong đợt này.

Kiểm tra cloud chỉ đọc, không gọi RPC cập nhật thống kê:

```powershell
npx supabase db query --linked --file tool/kanji/verify_decompositions_cloud.sql
```

## Phạm vi đã triển khai trước cây nhiều tầng

- Pipeline tái lập: 214 bộ Khang Hy, 2.136 Jōyō, 7.253 lần xuất hiện thành phần cuối; lớp 1–6 hoặc 8 (Trung học), không có JLPT.
- Schema, RLS, RPC thống kê thủ công và RPC đọc snapshot nguyên tử, không bị giới hạn 1.000 hàng của PostgREST.
- Tab Hán tự, hai lưới theo tần suất, dialog Bộ thủ mở Kanji liên quan, phân trang chuỗi như `先生`, trạng thái chưa hỗ trợ. Chip trong phân tích chọn/tô nét, không mở chi tiết bộ thủ.
- Phân tích từ Flashcard và kết quả tìm kiếm Trang chủ; không sửa SRS/từ vựng.
- KanjiVG CDN pin commit, cache bộ nhớ/lưu bền, từng nét tích lũy, phát/tạm dừng/vẽ lại, giảm chuyển động. SVG có transform không dùng được với bộ phát nét sẽ chuyển sang trình SVG tĩnh theo từng bước, đã lọc chỉ còn path/group. SVG hỏng hoàn toàn có thông báo lỗi và thử lại, không ngăn xem nghĩa/cách đọc.
- Attribution trong Cài đặt → Nguồn dữ liệu & giấy phép.

## Phân tích v2 và bước 0

- Duyệt cây đến bộ thủ/biến thể hoặc ngoại lệ `戌`, `⺍`. Giữ từng lần xuất hiện và ID nhóm/nét, không gộp chỉ vì cùng chữ. `element` và `original` được lưu riêng; ô `戌` của `機` giữ nguyên nét nguồn `戍`.
- `component_rules.json` lưu điểm dừng và ngoại lệ theo Kanji/ID nhóm. Nhóm `part` bị một điểm dừng cha che mất phần còn lại được mở rộng, không lấy trùng nét. Validator tính lại chính xác tập ngoại lệ này; thay đổi nguồn/quy tắc phải được rà soát trước khi sinh migration. Nhóm ghép riêng của `斎` và 17 trường hợp part đi qua các ngữ cảnh cây khác nhau được ghi tường minh; `audit_parts.py` in metadata/nhóm cha để rà soát. Đây là kiểm tra cấu trúc, không phải duyệt ngôn ngữ.
- Thành phần bổ sung không thuộc 214 bộ có `radical_id = null`; nét không có tên hiện “Nét phụ” với hình thu nhỏ. Các thành phần cuối phủ mỗi nét đúng một lần.
- Mở/chuyển chữ mặc định “Từng nét”, `Nét 0/N` hiện đầy đủ chữ. Bước 1–N tích lũy nét, không quay vòng. Animation vẫn bắt đầu từ chưa vẽ.
- Bấm ô dừng animation, về bước 0 và tô đỏ đúng ID nét của lần xuất hiện đó; khóa phát/bước cho tới khi bấm lại hoặc “Bỏ chọn”. Chuyển chữ xóa lựa chọn, kể cả hai chữ liên tiếp giống nhau.
- ID hoặc commit không khớp: giữ metadata nhưng không đoán nét; nút tải lại bỏ qua cache SVG và tải lại thành phần. SVG dự phòng giữ ID và tô màu từng path.

## Hợp đồng thống kê

`recalculate_user_kanji_and_radical_stats()` không nhận user ID từ client; chỉ dùng `auth.uid()` và chỉ đọc `vocabulary.kanji` của tài khoản đó, gồm cả bộ từ tạm dừng học.

- Mỗi lần xuất hiện được tính: `先生先生` cho 先=2, 生=2.
- Một bộ được tính một lần trên mỗi lần xuất hiện của Kanji chứa bộ đó: `森` cho 木=1, không phải 3. Các dạng của cùng bộ trong cùng Kanji cũng không nhân đôi số đếm.
- Snapshot `radical_forms` tách số đếm theo đúng `component_form`; một họ đã gặp luôn trả dạng gốc và toàn bộ biến thể theo thứ tự catalog, kể cả dạng có số đếm 0. `radicals` và `total_radical_count` vẫn giữ tổng theo họ để tương thích client cũ.
- Danh sách Kanji liên quan phải lọc bằng cả `radical_id` và `component_form`; khóa cache cũng dùng cả hai giá trị để các dạng cùng tên không dùng lẫn dữ liệu.
- `total_vocab_scanned` là số dòng từ vựng của tài khoản đã duyệt, gồm trường Kanji null/rỗng. Null, khoảng trắng, kana, 々, emoji và variation selector không tạo số đếm Kanji.
- `unsupported_kanji_count` là số **ký tự CJK khác nhau** ngoài danh mục, không phải số lần xuất hiện. Xử lý Unicode scalar, gồm chữ ngoài BMP và Extension J của Unicode 17.
- Thêm/sửa/xóa từ không tính lại. Đọc màn hình, đổi tab, mở dialog và thử tải lại cũng không gọi RPC tính toán. Không khóa sau 10 ngày.
- Nút cập nhật gọi RPC rồi đọc lại cả overview/hai lưới. Advisory lock theo tài khoản và transaction ngăn kết quả ghi dở dang khi hai thiết bị cùng tính hoặc RPC lỗi.
- `kanji_components` là phép chiếu duy nhất của các bộ tại điểm dừng; các thành phần bổ sung không được tính. `機` có hai ô 幺 nhưng chỉ đóng góp 幺=1.
- Snapshot cũ giữ nguyên số liệu/thời gian với `component_version = 1`; UI cảnh báo cần cập nhật và chưa hiện Kanji liên quan theo quan hệ mới. Chỉ RPC thủ công ghi phiên bản 2. Thay quan hệ và hàm RPC trong cùng transaction, không tự tính/xóa snapshot khi migration.

## Sinh lại seed và duyệt dữ liệu

Chạy từ gốc repo, cần Python 3 (thư viện chuẩn):

```powershell
python tool/kanji/build_seed.py --validate-only
python tool/kanji/build_seed.py --validate-only --release
python tool/kanji/build_seed.py --cache-only
python tool/kanji/build_components.py --cache-only
python tool/kanji/build_components.py --validate-only
python tool/kanji/test_components.py
```

Lần đầu cần mạng để lấy archive KanjiVG pin commit. Snapshot KANJIDIC2 đã lưu tại `sources/kanjidic2.xml.gz`; cả hai nguồn đều được kiểm SHA-256 theo `sources.lock.json`. Xóa riêng cache tải về rồi chạy lại vẫn dùng đúng nguồn. Không tự chấp nhận checksum mới.

Đầu vào biên tập:

- `radicals.tsv`: tên/nghĩa/số nét/dạng bộ thủ.
- `meanings_vi.tsv`: 2.136 nghĩa tiếng Việt nháp, diễn giải từ nghĩa Anh của KANJIDIC2.
- `curated_vi.json`: ghi đè nghĩa/âm Hán Việt và `review_status`. Âm Hán Việt còn lại lấy từ KANJIDIC2; hai chữ thiếu được bổ sung dưới trạng thái nháp.

`validation_report.json` là kết quả kiểm tra máy, **không thay thế duyệt ngôn ngữ**. `review_samples.md` có mẫu phân tầng theo lớp và các trường hợp cấu tạo dễ nhầm. Hiện không có ký tự nào được ghi là con người đã duyệt. Chia danh mục thành từng lô, sửa nội dung trong đầu vào rồi chỉ đặt `review_status: "approved"` cho những ký tự thực sự đã duyệt; nên lưu thêm `reviewer`, `reviewed_at`, `review_note` trong từng bản ghi. Gate `--release` yêu cầu toàn bộ 2.136 ký tự có dữ liệu và trạng thái approved. Do đó **gate phát hành hiện cố ý không pass**.

Đầu ra tự sinh: migration `202609050003_seed_kanji_catalog.sql`, `assets/kanji/sources.json`, báo cáo, mẫu duyệt và `.cache/catalog.json` dùng cho corpus test. Không viết tay SQL seed. Chỉ chạy generator để thay migration này khi nó **chưa triển khai**. Sau khi đã triển khai, đổi đích generator thành migration có timestamp mới, duyệt diff và bảo toàn lịch sử migration; khi thay đổi thành phần phải xử lý cả những quan hệ cũ bị loại bỏ.

Đối với v2, chỉ dùng `build_components.py`: sinh `202609060002_seed_kanji_component_occurrences.sql`, `component_validation_report.json` và `.cache/component_occurrences.json`; không chạm nghĩa/âm Hán Việt, trạng thái duyệt hoặc commit KanjiVG. `stats_v2.sql` là mẫu RPC được ghép vào transaction seed. Sau khi migration v2 triển khai, chỉ chạy `--validate-only` để kiểm tra; mọi thay đổi tiếp theo phải dùng timestamp mới. `--audit` chỉ xuất đề xuất ngoại lệ vào cache, không tự cập nhật quy tắc đã chốt.

Giấy phép/nguồn chi tiết ở `assets/kanji/ATTRIBUTION.md`. Trước phát hành thương mại, người phụ trách cần xác nhận attribution, phân phối dữ liệu phái sinh và quy trình cập nhật nguồn đáp ứng điều khoản EDRDG/KanjiVG. Không coi việc generator pass là xác nhận pháp lý.

## Cache/offline

- SVG: memory LRU 64 chữ; SharedPreferences/browser storage tối đa khoảng 2 MiB hoặc 100 SVG, khóa gồm phiên bản và code point. Khởi động lại vẫn đọc được SVG còn trong cache. Có thể bị loại bỏ khi vượt hạn mức hoặc khi người dùng xóa dữ liệu trình duyệt.
- Metadata/component/quan hệ cache dùng namespace v2, khoảng 1 MiB/200 mục. SVG giữ namespace/commit cũ để tái sử dụng offline. Snapshot thống kê lưu riêng theo user ID; không dùng snapshot của tài khoản khác.
- Khi offline và còn phiên đăng nhập, màn hình mất mạng có nút “Xem Hán tự đã lưu”. Mở lại các chữ đã xem không cần gọi cloud; nội dung chưa từng lưu cần tải lần đầu khi online.
- Không lưu token trong cache tính năng. Lỗi quyền, auth hoặc schema không bị che bởi snapshot cũ. Cache không thay thế Supabase làm nguồn dữ liệu chính, không có hàng đợi ghi offline.

## Kiểm thử

```powershell
flutter analyze
flutter test
flutter test test/features/kanji --dart-define=KANJI_CORPUS=true
flutter test test/features/kanji/kanji_ui_test.dart --dart-define=KANJI_CAPTURE=true
flutter build web --release
```

Corpus test cần chạy cả hai generator với `--cache-only` trước; tùy chọn này chỉ chuẩn bị dữ liệu test trong cache, không ghi đè migration đã triển khai. Capture là kiểm tra ảnh tùy chọn trên Windows, dùng Segoe UI tại `C:/Windows/Fonts/segoeui.ttf`, ghi PNG vào `build/kanji_qa/`; test thông thường không cần font hệ thống này. Bộ mới kiểm tra mapping/Unicode, không tự tính, đúp thao tác, lỗi, cache cách ly tài khoản, parser/toàn bộ SVG, fallback tĩnh, animation/giảm chuyển động, UI nhỏ/chữ lớn, điều hướng, dialog và hai điểm vào.

Database trên **Supabase local/staging test database**, không chạy trên production:

```powershell
supabase db reset
supabase test db
```

`supabase/tests/kanji_stats_test.sql` chứa 16 assertion pgTAP và dùng `fixtures/kanji_assertions.sql` để kiểm RPC/RLS dưới hai role người dùng. Fixtures rollback toàn bộ dữ liệu giả, kiểm chữ lặp, xóa từ, trường rỗng, chữ ngoài BMP, >1.000 kết quả và lỗi giữa transaction.

`kanji_occurrences_test.sql` bổ sung schema/RLS/đếm bộ lặp/quy tắc mới và phiên bản snapshot. Harness PGlite còn tạo snapshot bằng RPC v1 trước khi chạy migration v2 rồi so sánh toàn bộ số liệu/thời gian sau migration. `node tool/kanji/test_database.mjs --assertions-only` chạy các assertion mà không ghi đè báo cáo benchmark cũ.

Fallback khi chưa có Supabase CLI/Postgres local:

```powershell
python tool/kanji/prepare_test_db.py
node tool/kanji/test_database.mjs
```

Harness PGlite pin 0.3.14 tạo Postgres WASM riêng trong bộ nhớ, giả lập `auth.uid()`/role, chạy toàn bộ migrations và **cùng assertions giao dịch**; không kết nối cloud. Nó không chạy extension pgTAP hay hệ thống Supabase Auth/PostgREST thật. Benchmark 1.000/10.000/50.000 dòng ghi `benchmark_report.json`; số đo này không phải độ trễ production và không chứng minh mục tiêu <50 ms. Cần benchmark lại trên staging qua RPC với hạ tầng/dữ liệu gần thực tế.

## Checklist trước phát hành

Kết quả v2 ngày 2026-09-06: `flutter analyze` không có lỗi; **153 tests pass** khi bật cả corpus 2.136 SVG và capture UI; 5 test Python và assertions database PGlite pass; seed sinh lại có cùng checksum. Ảnh 6 chữ mẫu kiểm tra nét đỏ, theme sáng/tối, nét phụ và fallback SVG. Release gate vẫn yêu cầu con người duyệt dữ liệu như trước. Lần thử trước với `flutter test --platform chrome` dừng ở loading, đã hủy; không ghi nhận là pass kiểm thử trình duyệt.

Đã chạy `supabase db push --linked` cho `202609060001–002`, dry-run sau đó báo up to date. Kiểm tra cloud chỉ đọc bằng `supabase db query --linked --file tool/kanji/verify_cloud.sql`: 214 bộ, 2.136 Kanji có dữ liệu, 7.253 occurrences, 5.776 quan hệ bộ tại điểm dừng, không chồng ID nét; các chữ mẫu khớp. Authenticated chỉ đọc catalog, anon không đọc/catalog hoặc gọi RPC. Không gọi RPC tính lại cho tài khoản người dùng.

Giới hạn môi trường hiện tại: bản web có thể build; Android debug bị Java/Gradle báo `Unable to establish loopback connection` trên máy này (thử IPv4 vẫn lỗi); iOS chưa build/test được trên Windows. Không coi các nền tảng này đã nghiệm thu chỉ vì widget test pass.

Build web release v2 đã thành công. Còn cảnh báo dry-run WebAssembly trong `flutter_tts` và font Cupertino của dự án; bản build này là web JavaScript, không phải xác nhận hỗ trợ Wasm. Chưa phát hành client hay commit code của đợt cập nhật này.
