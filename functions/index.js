const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

/**
 * Envia push FCM quando uma notificação interna `badge_earned` é criada.
 */
exports.sendBadgePush = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    if (data.type !== "badge_earned") {
      return null;
    }

    const userId = context.params.userId;
    const badgeName = (data.badgeName || "Novo badge").toString();

    try {
      const tokensSnap = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("fcm_tokens")
        .get();
      const tokens = tokensSnap.docs
        .map((d) => (d.data().token || "").toString())
        .filter((t) => t.length > 0);

      if (tokens.length === 0) {
        functions.logger.info(`No FCM tokens for user ${userId}`);
        return null;
      }

      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "Novo badge conquistado!",
          body: `Você desbloqueou: ${badgeName}`,
        },
        data: {
          type: "badge_earned",
          badgeId: (data.badgeId || "").toString(),
          route: "profile_badges_drawer",
        },
      });

      const invalidTokens = [];
      response.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error && r.error.code ? r.error.code : "";
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(tokens[i]);
          }
        }
      });

      await Promise.all(
        invalidTokens.map((token) =>
          admin
            .firestore()
            .collection("users")
            .doc(userId)
            .collection("fcm_tokens")
            .doc(token)
            .delete()
        )
      );
    } catch (error) {
      functions.logger.error("sendBadgePush error", error);
    }
    return null;
  });
