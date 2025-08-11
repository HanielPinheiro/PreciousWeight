package precious_weight.auth.models.request;

public class UserRequest {
        private String username;
        private String password;
        private String organization;

        // Default constructor (required for deserialization)
        public UserRequest() {
        }

        // Parameterized constructor
        public UserRequest(String username, String password, String organization) {
            this.username = username;
            this.password = password;
            this.organization = organization;
        }

        // Getters and setters
        public String getUsername() {
            return username;
        }
        public void setUsername(String username) {
            this.username = username;
        }

        public String getPassword() {
            return password;
        }
        public void setPassword(String password) {
            this.password = password;
        }

        public String getOrganization() { return organization; }
        public void setOrganization(String organization) {
            this.organization = organization;
        }

}
