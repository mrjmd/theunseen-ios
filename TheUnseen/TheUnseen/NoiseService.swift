import Foundation
import CryptoKit

class NoiseService {

    enum HandshakeRole {
        case initiator
        case responder
    }

    private enum HandshakeState {
        case initial
        case awaitingEphemeralReply
        case complete
    }

    private var role: HandshakeRole
    private var state: HandshakeState = .initial

    private let staticKey: Curve25519.KeyAgreement.PrivateKey
    private let ephemeralKey: Curve25519.KeyAgreement.PrivateKey

    private var remoteStaticPublicKey: Curve25519.KeyAgreement.PublicKey?
    private var remoteEphemeralPublicKey: Curve25519.KeyAgreement.PublicKey?
    
    private var sendingKey: SymmetricKey?
    private var receivingKey: SymmetricKey?

    init(role: HandshakeRole) {
        self.role = role
        self.staticKey = Curve25519.KeyAgreement.PrivateKey()
        self.ephemeralKey = Curve25519.KeyAgreement.PrivateKey()
    }

    func createInitialHandshakeMessage() -> Data? {
        guard role == .initiator else { return nil }
        
        let message = ephemeralKey.publicKey.rawRepresentation
        self.state = .awaitingEphemeralReply
        return message
    }
    
    func handleInitialHandshakeMessage(_ message: Data) -> Data? {
        guard role == .responder, state == .initial else { return nil }

        guard let remoteEphemeralKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: message) else {
            return nil
        }
        
        self.remoteEphemeralPublicKey = remoteEphemeralKey
        let replyMessage = ephemeralKey.publicKey.rawRepresentation
        deriveSymmetricKeys()
        self.state = .complete
        return replyMessage
    }
    
    // This function now returns a Bool to indicate success.
    func handleResponderReplyMessage(_ message: Data) -> Bool {
        guard role == .initiator, state == .awaitingEphemeralReply else { return false }

        guard let remoteEphemeralKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: message) else {
            return false
        }

        self.remoteEphemeralPublicKey = remoteEphemeralKey
        deriveSymmetricKeys()
        self.state = .complete
        print("Handshake state is now complete.")
        return true
    }
    
    func isExpectingInitialMessage() -> Bool {
        return self.role == .responder && self.state == .initial
    }
    
    func isHandshakeComplete() -> Bool {
        return self.state == .complete
    }
    
    private func deriveSymmetricKeys() {
        guard let remoteEphemeralKey = self.remoteEphemeralPublicKey else { return }

        do {
            let sharedSecret = try ephemeralKey.sharedSecretFromKeyAgreement(with: remoteEphemeralKey)
            let salt = "TheUnseenSalt".data(using: .utf8)!
            
            let derivedKeyMaterial = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: salt,
                sharedInfo: "TheUnseenInfo".data(using: .utf8)!,
                outputByteCount: 64
            )
            
            derivedKeyMaterial.withUnsafeBytes { buffer in
                let keyData = Data(buffer)
                let sendingKeyData = keyData.prefix(32)
                let receivingKeyData = keyData.suffix(32)

                if role == .initiator {
                    self.sendingKey = SymmetricKey(data: sendingKeyData)
                    self.receivingKey = SymmetricKey(data: receivingKeyData)
                } else {
                    self.sendingKey = SymmetricKey(data: receivingKeyData)
                    self.receivingKey = SymmetricKey(data: sendingKeyData)
                }
            }
            
            print("✅ Symmetric keys derived successfully for \(role).")

        } catch {
            print("Error deriving symmetric keys: \(error)")
        }
    }

    func encrypt(_ plaintext: String) -> Data? {
        guard let sendingKey = self.sendingKey, let data = plaintext.data(using: .utf8) else {
            print("Error: Keys not ready or invalid plaintext for encryption.")
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: sendingKey)
            print("✉️ Encrypted message successfully.")
            return sealedBox.combined
        } catch {
            print("Error encrypting message: \(error)")
            return nil
        }
    }

    func decrypt(_ encryptedData: Data) -> String? {
        guard let receivingKey = self.receivingKey else {
            print("Error: Keys not ready for decryption.")
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: receivingKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Error decrypting message: \(error)")
            return nil
        }
    }
}
