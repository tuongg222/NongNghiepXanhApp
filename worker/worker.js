import { handleData } from "./data_api.js";
import { handleAuth } from "./auth.js";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Content-Type": "application/json; charset=utf-8"
};


function cleanAIAnswer(value) {
  if (typeof value !== "string") return String(value ?? "");

  let text = value
    .replace(/\r/g, "")
    .replace(/(\*\*){1,}/g, "")
    .replace(/[ \t]+/g, " ")
    .trim();

  // Xóa các dòng trùng nhau liên tiếp
  const lines = text.split("\n");
  const cleanLines = [];
  for (const line of lines) {
    const current = line.trim();
    if (!current) {
      if (cleanLines.length && cleanLines[cleanLines.length - 1] !== "") {
        cleanLines.push("");
      }
      continue;
    }
    if (cleanLines[cleanLines.length - 1] !== current) {
      cleanLines.push(current);
    }
  }
  text = cleanLines.join("\n").trim();

  // Loại câu trùng nguyên văn
  const sentences = text.split(/(?<=[.!?。！？])\s+/);
  const seen = new Set();
  const unique = [];
  for (const sentence of sentences) {
    const key = sentence.trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    unique.push(sentence.trim());
  }
  text = unique.join(" ").trim();

  // Giới hạn đầu ra để tránh nội dung lặp quá dài
  if (text.length > 6500) {
    text = text.slice(0, 6500).trim() + "\n\n(Nội dung đã được rút gọn.)";
  }
  return text;
}

function reply(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: CORS
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS });
    }

    if (url.pathname === "/data") {
      try {
        return await handleData(request, env);
      } catch (error) {
        console.error("Data API error:", error);
        return reply({ error: "Lỗi xử lý dữ liệu." }, 500);
      }
    }

    if (url.pathname.startsWith("/auth/")) {
      try {
        return await handleAuth(request, env, url);
      } catch (error) {
        console.error("Auth API error:", error);
        return reply({ error: "Lỗi xử lý tài khoản.", code: error?.name || "UnknownError" }, 500);
      }
    }

    if (url.pathname === "/health" && request.method === "GET") {
      return reply({
        ok: true,
        service: "nongnghiep-xanh-ai",
        aiConnected: Boolean(env.AI)
      });
    }

    if (url.pathname === "/" && request.method === "GET") {
      return env.ASSETS.fetch(request);
    }


    // NONG NGHIEP XANH - AI CHAT
    if (url.pathname === "/chat") {
      if (request.method !== "POST") {
        return reply({ error: "Chi chap nhan POST." }, 405);
      }

      if (!env.AI) {
        return reply({ error: "Workers AI chua duoc cau hinh." }, 503);
      }

      let body;
      try {
        body = await request.json();
      } catch {
        return reply({ error: "JSON khong hop le." }, 400);
      }

      const question = typeof body.message === "string"
        ? body.message.replace(/[\u0000-\u001f]+/g, " ").trim().slice(0, 2000)
        : "";

      const context = typeof body.context === "string"
        ? body.context.replace(/[\u0000-\u001f]+/g, " ").trim().slice(0, 2000)
        : "";

      if (!question) {
        return reply({ error: "Hay nhap cau hoi." }, 400);
      }

      try {
        const result = await env.AI.run(
          "@cf/meta/llama-3.2-11b-vision-instruct",
          {
            messages: [
              {
                role: "system",
                content:
                  "Ban la Nong Nghiep Xanh AI, tro ly nong nghiep Viet Nam. " +
                  "Tra loi bang tieng Viet tu nhien, than thien, ro rang va de ap dung. " +
                  "Uu tien lua, cay trong, dat, nuoc, thoi tiet, dinh duong, sau benh, " +
                  "lich cham soc va kinh te mua vu. " +
                  "Giai thich vi sao, neu cac buoc thuc hien va dieu kien ap dung. " +
                  "Khong tu bia du lieu thoi tiet, gia nong san hay ket qua xet nghiem. " +
                  "Khong chan doan chac chan khi thieu bang chung. " +
                  "Khong tu dua lieu luong thuoc, pha tron hoa chat hay khuyen cao " +
                  "phun thuoc khi chua xac dinh doi tuong; huong dan tham khao " +
                  "can bo bao ve thuc vat va doc dung nhan san pham. " +
                  "Neu cau hoi ngoai nong nghiep, van tra loi lich su va huu ich."
              },
              {
                role: "user",
                content:
                  (context ? "Thong tin ruong/vuon:\n" + context + "\n\n" : "") +
                  "Cau hoi: " + question
              }
            ],
            max_tokens: 900
          }
        );

        const answer = result?.response || result?.description;
        if (!answer) {
          return reply({ error: "AI chua tao duoc cau tra loi." }, 502);
        }

        return reply({
          ok: true,
          aiConnected: true,
          answer: answer
        });
      } catch (error) {
        console.error("Chat AI error:", error);
        return reply({
          error: "AI chat loi: " + String(error?.message || error).slice(0, 250)
        }, 502);
      }
    }

    if (url.pathname !== "/diagnose") {
      return reply({ error: "Không tìm thấy endpoint." }, 404);
    }

    if (request.method !== "POST") {
      return reply({ error: "Chỉ chấp nhận POST." }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return reply({ error: "Dữ liệu JSON không hợp lệ." }, 400);
    }

    if (
      typeof body.image !== "string" ||
      !/^data:image\/(jpeg|jpg|png|webp);base64,/i.test(body.image)
    ) {
      return reply({
        error: "Cần gửi ảnh JPG, PNG hoặc WebP dạng base64."
      }, 400);
    }

    if (body.image.length > 5_000_000) {
      return reply({ error: "Ảnh quá lớn. Hãy chọn ảnh nhỏ hơn." }, 413);
    }
    const context = typeof body.context === "string"
      ? body.context.replace(/[\u0000-\u001f]+/g, " ").trim().slice(0, 1600)
      : "";

    if (!env.AI) {
      return reply({
        error: "Workers AI chưa được cấu hình.",
        aiConnected: false
      }, 503);
    }

    try {
      const result = await env.AI.run(
        "@cf/meta/llama-3.2-11b-vision-instruct",
        {
          messages: [
            {
              role: "system",
              content:
                "Bạn là AI hỗ trợ chẩn đoán và chăm sóc lúa tại Việt Nam. " +
                "Trả lời hoàn toàn bằng tiếng Việt, ngắn gọn, dễ đọc trên điện thoại. " +
                "Phân tích trực tiếp ảnh: chỉ nêu dấu hiệu thực sự nhìn thấy; không bịa. " +
                "Không lặp câu, không nhắc lại cùng ý, không viết mở bài dài. " +
                "Nếu ảnh không đủ rõ, nói rõ giới hạn và không đoán chắc tên bệnh. " +
                "Chỉ dùng đúng 5 mục sau, mỗi mục tối đa 2 gạch đầu dòng ngắn: " +
                "1. KẾT LUẬN SƠ BỘ: khả năng đáng nghi nhất và mức độ chắc chắn. " +
                "2. DẤU HIỆU TRONG ẢNH: 2-3 dấu hiệu nhìn thấy cụ thể. " +
                "3. NGUYÊN NHÂN CÓ THỂ: tối đa 2 khả năng, giải thích ngắn vì sao. " +
                "4. CÁCH KIỂM TRA VÀ XỬ LÝ: 2-3 bước an toàn, thực tế, làm được ngay. " +
                "5. PHÒNG NGỪA / CẦN BỔ SUNG: điều cần theo dõi và tối đa 2 thông tin cần hỏi. " +
                "Không tự kê thuốc, hoạt chất, liều lượng hoặc pha trộn thuốc. " +
                "Nếu nghi bệnh cần xác minh trước khi xử lý thuốc, khuyên hỏi cán bộ bảo vệ thực vật. " +
                "Tổng câu trả lời khoảng 180-300 từ, ưu tiên câu ngắn. " +
                "Kết thúc trọn câu, không lặp tiêu đề hoặc nội dung."
            },
            {
              role: "user",
              content:
                "Phân tích ảnh cây lúa này theo đúng 5 mục trong hướng dẫn. " +
                "Ưu tiên nhận diện dấu hiệu ảnh, nêu kết luận sơ bộ có mức độ tin cậy, " +
                "hướng kiểm tra và hành động an toàn. Không lặp lại yêu cầu, không viết dài. " +
                (context ? "\nNgữ cảnh người trồng cung cấp (chưa xác minh):\n" + context : "")
            }
          ],
          max_tokens: 550,
          image: body.image.substring(body.image.indexOf(",") + 1)
        }
      );

      const answer =
        result?.response ||
        result?.description ||
        result?.result;

      const cleanedAnswer = cleanAIAnswer(answer);
      if (!cleanedAnswer) {
        return reply({
          error: "Mô hình không trả về nội dung phân tích.",
          aiConnected: true
        }, 502);
      }

      return reply({
        ok: true,
        aiConnected: true,
        result: cleanedAnswer
      });
    } catch (error) {
      const detail = String(error?.message || error || "Unknown error");
      console.error("Workers AI error:", detail);
      if (detail.includes("5016") || /must submit the prompt ['\"]agree['\"]/i.test(detail)) {
        return reply({
          error: "Cloudflare yêu cầu chủ dự án chấp nhận giấy phép Meta Llama trước khi dùng mô hình. Mở Cloudflare Workers AI, chọn llama-3.2-11b-vision-instruct và hoàn tất bước chấp nhận giấy phép. Ứng dụng không tự đồng ý thay bạn.",
          code: "MODEL_LICENSE_REQUIRED",
          license: "https://github.com/meta-llama/llama-models/blob/main/models/llama3_2/LICENSE"
        }, 503);
      }
      return reply({
        error: "Workers AI gặp lỗi: " + detail.slice(0, 300),
        code: "WORKERS_AI_ERROR",
        aiConnected: false
      }, 502);
    }
  }
};
