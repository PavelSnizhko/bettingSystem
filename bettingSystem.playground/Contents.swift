import Foundation


//TODO: think about Hashable and SET for User actor
// lazy array

protocol User {
    var id: Int {get set}
    var userName: String {get set}
    var password: String {get set}
}


struct Admin: User {
    var id: Int
    var userName: String
    var password: String
    
    
}


struct RegularUser: User {
    var id: Int
    var userName: String
    var password: String
    
}


enum Role {
    case admin
    case regularUser
}


struct UserStorage {
    let id: Int
    var users: [Int: User] = [0 : Admin(id: 0, userName: "User0", password: "12345"),
                              1 : RegularUser(id: 1, userName: "User1", password: "12345"),
                              2 : RegularUser(id: 2, userName: "User2", password: "12345"),
                              3 : RegularUser(id: 3, userName: "User3", password: "12345"),
                              4 : RegularUser(id: 4, userName: "User4", password: "12345")
                             ]
    func getUserById(id: Int) -> User? {
        return self.users[id] ?? nil
    }
    
    func getUsers() -> [User] {
        return [User](users.values)
    }
}


struct Bet {
    let id: Int
    let name: String
}


struct BetStorage {
    var bets: [Int: Bet] = [0: Bet(id: 0, name: "Milan - Uventus 2:0"),
                            1: Bet(id: 1, name: "Barselona  - RM 10:0"),
                            2: Bet(id: 1, name: "D  - Sh 5:5")]
}


class AuthSystem {
    
    func logIn(userName: String, password: String) -> Bool {
      // TODO: implement logic for this func
        return true
    }
    
    func logOut(user: User) -> Bool {
        // TODO: implement logic for this func
        return true
    }
    
    
}



class System {
    private var currentUser: User?
    private let authSystem: AuthSystem = AuthSystem()
    
    
    func placeBet (){}
    func showUsers (){}
    
    

}
