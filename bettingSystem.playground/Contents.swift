import Foundation

//MARK: Aliases
typealias UserCompletion = (Result<User,BettingSystemError>) -> ()
typealias BetCompletion = (Result<Bet,BettingSystemError>) -> ()
typealias FunctionSucces = (Result<Void, BettingSystemError>) -> ()
typealias PowerStorageManager = StorageManager & StorageManagerRegularUser



//MARK: Errors
enum BettingSystemError: String, Error {
    case userIsAlreadyRegister = "This username is already taken"
    case userIsAlreadyBanned = "This user is banned"
    case badData = "Wrong username or password"
    case userDoesNotExist = "User does not exist"
    case userIsInBlacklist = "You are in the blacklist"
    case systemIsBusy = "System is already used"
    case premmisionFaild = "You are not allowed to use this function"
    case opperationCanceled = "Operation can't be done"
    case betIsAlreadyPlaced = "The bet is already placed"
}



//MARK: User
protocol User {
    var username: String {get set}
    var password: String {get set}
    var role: Role {get set}
}


struct Admin: User {
    var username: String
    var password: String
    var role: Role

}


struct RegularUser: User {
    var username: String
    var password: String
    var role: Role
    var isBanned: Bool
    
}


enum Role {
    case admin
    case regularUser
}


struct UsersStorage {
    var users: [String: User] = [:]
}


// MARK: StorageManager & UserStorageManager
protocol StorageManager {
    func isUserExist(username: String) -> Bool
    func getUserByUsername(username: String) -> User?
    func getUsers() -> [User]
    func addUser(user: User)
}

protocol StorageManagerRegularUser {
    func getRegularUsers() -> [String]
    func banRegularUser(username: String, completion: FunctionSucces)
}




class UsersStorageManager: PowerStorageManager {
    
    
    private var usersStorage: UsersStorage = UsersStorage()
    
    func banRegularUser(username: String, completion: FunctionSucces) {
        guard var regularUser = usersStorage.users[username] as? RegularUser else {
            completion(.failure(.userDoesNotExist))
            return
        }
        regularUser.isBanned = true
        addUser(user: regularUser)
        completion(.success(()))
    }
    
    
    func getRegularUsers() -> [String] {
        var usernames: [String] = []
        for (key, user) in self.usersStorage.users{
            guard let user = user as? RegularUser, !user.isBanned  else { continue }
            usernames.append(key)
        }
        
        return usernames
    }

    func getUserByUsername(username: String) -> User? {
        usersStorage.users[username]
    }
    
    func getUsers() -> [User] {
        [User](self.usersStorage.users.values)
    }
    
    
    func isUserExist(username: String) -> Bool {
        usersStorage.users[username] != nil
    }
    
    func addUser(user: User) {
        usersStorage.users[user.username] = user
    }
    

}


// MARK: Bet & BetStorage & BetStorageManager
struct Bet: Hashable{
    let description: String
    
}

extension Bet {
    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
        
}


struct BetStorage {
    var bets: [String: Set<Bet>] = ["Sasha": [ Bet(description: "Milan - Uventus 2:0"), Bet(description: "Barselona  - RM 0:0"), Bet(description: "D  - Sh 5:5")]]

}


protocol BetStorageManager {
    func getBets(for username: String) -> Set<Bet>
    func addBet(username: String, bet: Bet, completion: FunctionSucces)
}


class BetManager: BetStorageManager {
    private var betStorage = BetStorage()
    
    func addBet(username: String, bet: Bet, completion: FunctionSucces){
        guard let result = betStorage.bets[username]?.insert(bet) else {
            betStorage.bets[username] = [bet]
            completion(.success(()))
            return
        }
        if result.inserted {
            completion(.success(()))
            return
        }
        else {
            completion(.failure(.betIsAlreadyPlaced))
        }
    }
    
    func getBets(for username: String) -> Set<Bet> {
        betStorage.bets[username] ?? Set()
    }
}





// MARK: AuthenticationSystem
class AuthSystem {
    private var storageManager: StorageManager
 
    
    init(storageManager: UsersStorageManager) {
        self.storageManager = storageManager
    }
    
    func register(username: String, password: String, role: Role, completion: FunctionSucces) {
        
        if username.isEmpty || password.isEmpty {
            completion(.failure(.badData))
            return
        }
        
        guard !(self.storageManager.isUserExist(username: username)) else {completion(.failure(.userIsAlreadyRegister)); return}
        
        switch role {
        case .admin:
            storageManager.addUser(user: Admin(username: username, password: password, role: .admin))
            completion(.success(()))
            return
        case .regularUser:
            storageManager.addUser(user: RegularUser(username: username, password: password, role: .regularUser, isBanned: false))
            completion(.success(()))
            return
        }
    }
    
    func login(username: String, password: String, completion: UserCompletion) {
        if username.isEmpty || password.isEmpty {
            completion(.failure(.badData))
            return
        }
        
        guard let user = storageManager.getUserByUsername(username: username) else { completion(.failure(.userDoesNotExist)); return }
        guard user.password == password else { completion(.failure(.badData)); return }
        if user.role != .admin, let regularUser = user as? RegularUser, regularUser.isBanned{
            completion(.failure(.userIsInBlacklist))
        }else{
            completion(.success(user))
        }
    }

}


enum State {
    case isBusy
    case isFree
}

class BettingSystem {
    private var state: State = .isFree
    private var usersManager: PowerStorageManager
    private var betManager: BetStorageManager
    private let authSystem: AuthSystem
    
    
    init(storageManager: PowerStorageManager, betManager: BetStorageManager) {
        self.usersManager = storageManager
        self.betManager = betManager
        self.authSystem = AuthSystem(storageManager: self.usersManager as! UsersStorageManager)
    }
    
    private var currentUser: User? {
        didSet {
            if currentUser == nil {
                self.state = .isFree
            }
            else {
                self.state = .isBusy
            }
        }
    }

    func registration(username: String, password: String, role: Role) {
        if self.state != .isFree{
            print(BettingSystemError.systemIsBusy.rawValue)
            return
        }
        else {
            authSystem.register(username: username, password: password, role: role) {result in
                switch result {
                case .success():
                    print("Registrtion was succesfully done. Move to log in")
                case .failure(let error):
                    print(error.rawValue)
                }
            }
        }
        
        
    }
    
    func logIn(username: String, password: String) {
        if self.state != .isFree{
            print(BettingSystemError.systemIsBusy.rawValue)
        }
        else {
            authSystem.login(username: username, password: password) { [weak self] result in
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    print("Congrats! You are in system")
                case .failure(let error):
                    print(error.rawValue)
                }
            }
        }
    }
    
    func logOut(){
        if self.state == .isFree {
            print(BettingSystemError.premmisionFaild.rawValue)
        }
        else {
            self.currentUser = nil
            print("Log out: Thanks for using our system")
        }
    }
    
    func placeBet (bet: Bet) {
        guard self.state == .isBusy && currentUser?.role == .regularUser, let username = currentUser?.username  else {
            print(BettingSystemError.premmisionFaild.rawValue)
            return
        }
        
        betManager.addBet(username: username, bet: bet) { result in
            switch result {
            case .success():
                print("Your bet is accepted")
            case .failure(let error):
                print(error.rawValue)
            }
        }
    }
    
    
    func showUsers () {
        guard self.state == .isBusy && currentUser?.role == .admin else {
            print(BettingSystemError.premmisionFaild.rawValue)
            return
        }
        print(usersManager.getRegularUsers().reduce("", {(text, bet) in
                                                        "\(text) \n \(bet.description)"}))
    }
    
    func banUser(username: String) {
        guard self.state == .isBusy && currentUser?.role == .admin else {
            print(BettingSystemError.premmisionFaild.rawValue)
            return
        }
        usersManager.banRegularUser(username: username) { result in
            switch result {
            case .success():
                print("\(username) is banned ")
            case .failure(let error):
                print(error.rawValue)
            }
        }
    }
    
    func printAllBets() {
        guard self.state == .isBusy && currentUser?.role == .regularUser, let username = currentUser?.username else {
            print(BettingSystemError.premmisionFaild.rawValue)
            return
        }
        print(betManager.getBets(for: username).reduce("", {(text, bet) in
                                                        "\(text) \n \(bet.description)"}))
    }
}


let system = BettingSystem(storageManager: UsersStorageManager(), betManager: BetManager())
system.registration(username: "User1", password: "4546546", role: .admin)
system.registration(username: "User2", password: "4546546", role: .regularUser)
system.registration(username: "User3", password: "4546546", role: .admin)
system.registration(username: "User4", password: "4546546", role: .regularUser)
system.registration(username: "User4", password: "4546546", role: .regularUser)
system.registration(username: "User5", password: "123", role: .admin)


system.logIn(username: "User1", password: "4546546")
system.showUsers()

system.banUser(username: "User2")
system.showUsers()
system.logOut()
system.logIn(username: "User2", password: "4546546")
system.placeBet(bet: Bet(description: "Milan - Juventus 2:0"))
system.printAllBets()
system.logIn(username: "User4", password: "4546546")
system.placeBet(bet: Bet(description: "Gvatemala - Ukraine 0 : 30"))
system.placeBet(bet: Bet(description: "France - Ukraine 0 : 30"))
system.printAllBets()
system.logOut()

system.logIn(username: "User2", password: "4546546")
system.printAllBets()
system.placeBet(bet: Bet(description: "France - Ukraine 0 : 30"))
system.showUsers()
system.logOut()
system.logIn(username: "User5", password: "123")
system.showUsers()
system.printAllBets()
system.banUser(username: "pasha")
system.placeBet(bet: Bet(description: "Gvatemala - Ukraine 0 : 30"))
system.printAllBets()
