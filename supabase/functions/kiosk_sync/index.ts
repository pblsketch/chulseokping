// KO-1/KO-2/KO-3 지원: 키오스크 동기화 — device_token이 인증 수단(사용자 JWT 없음).
// 반환: 학급 정보 + 회전 QR/비컨 secret + 활성 세션. 키오스크는 이걸로 QR·minor를 로컬 계산한다.
// 검증은 여전히 서버(check_in_*)가 한다 — secret은 표시/광고용.
import { json, loadActiveSessionOfClass, parseCheckInBody, serviceClient } from "../_shared/checkin.ts";

Deno.serve(async (req) => {
  const parsed = await parseCheckInBody(req);
  if ("error" in parsed) return parsed.error;
  const { body } = parsed;

  const deviceToken = body.device_token as string | undefined;
  if (!deviceToken) return json(400, { error: "missing_fields" });

  const svc = serviceClient();

  const { data: device } = await svc
    .from("kiosk_devices")
    .select("id, class_id, beacon_major, beacon_secret")
    .eq("device_token", deviceToken)
    .eq("revoked", false)
    .maybeSingle();
  if (!device) return json(401, { error: "unknown_device" });

  const [{ data: classRow }, { data: secretRow }, session] = await Promise.all([
    svc.from("classes").select("name").eq("id", device.class_id).maybeSingle(),
    svc
      .from("class_secrets")
      .select("qr_secret")
      .eq("class_id", device.class_id)
      .maybeSingle(),
    loadActiveSessionOfClass(svc, device.class_id),
    svc
      .from("kiosk_devices")
      .update({ last_seen_at: new Date().toISOString() })
      .eq("id", device.id),
  ]);

  return json(200, {
    device_id: device.id,
    class_id: device.class_id,
    class_name: classRow?.name ?? "",
    beacon_major: device.beacon_major,
    beacon_secret: device.beacon_secret,
    qr_secret: secretRow?.qr_secret ?? null,
    session: session
      ? { id: session.id, type: session.type, period: session.period }
      : null,
  });
});
