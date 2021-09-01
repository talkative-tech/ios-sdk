import Foundation

class TalkativeHelper {

    static func onlineCheck(companyUuid: String, queueUuid: String, region: String, completion: @escaping (OnlineResponse?, Error?) -> Void) {
        let session = URLSession.shared
        
        let url = URL(string: getUrlForRegion(region: region) + "/api/v1/controls/online")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let json = [
            "talkative_version": "1.27.1",
            "talkative_company_uuid": companyUuid,
            "talkative_queue_uuid": queueUuid
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])

        let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                // Serialize the data into an object
                do {
                    let json = try JSONDecoder().decode(OnlineResponse.self, from: data )
                    completion(json, nil)

                } catch {
                    print("Error during JSON serialization: \(error.localizedDescription)")
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        };

        task.resume();
    }
    
    static func getUrlForRegion(region: String) -> String {        
        return "https://" + region + ".engage.app";
    }
}


struct OnlineResponse: Codable {
    let status: String
    let features: Features
}

struct Features: Codable {
    let chat, video: Bool
}

struct Reasons: Codable {
    let chat, video: String
}

struct InteractionDataEntry: Codable {
    let label, data, type: String
}
