const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// ---------- ดึง token ของ user ทุกคนที่มี fcmToken ----------
/**
 * Fetches FCM tokens for all users that have one saved.
 * @return {Promise<string[]>} Array of FCM tokens.
 */
async function getAllTokens() {
  const snap = await db.collection("users").get();
  const tokens = [];
  snap.forEach((doc) => {
    const t = doc.data().fcmToken;
    if (t) tokens.push(t);
  });
  return tokens;
}

// ---------- ข่าวใหม่ถูกสร้าง → แจ้งทุกคน ----------
exports.onNewsCreated = onDocumentCreated("news/{newsId}", async (event) => {
  const data = event.data.data();
  const tokens = await getAllTokens();
  if (tokens.length === 0) return;

  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: "📢 ประกาศใหม่",
      body: data.title || "มีประกาศใหม่จากแอดมิน",
    },
    data: {
      type: "news",
      newsId: event.params.newsId,
    },
  });
});

// ---------- Report ใหม่ → แจ้งเฉพาะ severity สูง (high) เท่านั้น ----------
exports.onReportCreated = onDocumentCreated(
    "reports/{reportId}",
    async (event) => {
      const data = event.data.data();

      // [severity-gate] ไม่ใช่ high → ไม่ต้องดึง token ไม่ต้องส่งอะไรเลย
      if (data.severity !== "high") {
        return;
      }

      const tokens = await getAllTokens();
      if (tokens.length === 0) return;

      await getMessaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "🔴 แจ้งปัญหาใหม่ (ร้ายแรง)",
          body: data.description || "มีการแจ้งปัญหาระดับร้ายแรงใหม่",
        },
        data: {
          type: "report",
          severity: data.severity,
          reportId: event.params.reportId,
        },
      });
    },
);