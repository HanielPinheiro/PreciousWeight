const lbl_home_br = "Home";
const lbl_babies_br = "Bebês";
const lbl_scales_br = "Balanças";
const lbl_logs_br = "Registros";

const lbl_login_email_br = "E-mail";
const lbl_login_email_lbl_br = "Digite seu e-mail";
const lbl_login_senha_br = "Senha";
const lbl_login_senha_lbl_br = "Digite a senha";

const lbl_connect_scale_to_network_br = "Conectar Balança ao Wi-Fi";
const lbl_scale_already_connected_br = "Balança já está conectada ao Wi-Fi";
const lbl_wifi_data_br = "Dados do Wi-Fi";
const lbl_wifi_login_br = "Nome da Rede Wi-Fi";
const lbl_wifi_login_lbl_br = "Digite o nome da rede";
const lbl_wifi_pass_br = "Senha do Wi-Fi";
const lbl_wifi_btn_connect_br = "Conectar";
const lbl_wifi_btn_ble_permission_br = "Conceder Permissões";

const lbl_home = "Home";
const lbl_babies = "Babies";
const lbl_scales = "Scales";
const lbl_logs = "Registers";
const lbl_connect_scale_to_network = "Connect Scale to WiFi";

const address_localhost = "http://localhost:8080";
const address_api = "http://100.96.1.34:8080"; //No android, localhost é 10.0.2.2, e não "localhost" ou "127.0.0.1"
//const address_api = "http://10.208.28.26:8080"; //No android, localhost é 10.0.2.2, e não "localhost" ou "127.0.0.1"

const api_pattern_code = "{code}";
const api_pattern_hash = "{hash}";

const api_audit_babies = "/audit/babies/{code}";
const api_audit_scales = "/audit/scales/{code}";
const api_audit_weights = "/audit/weights/{code}";

const api_baby_list = "/babies/list";
const api_baby_search = "/babies/search/{code}";
const api_baby_new = "/babies/save";
const api_baby_getQr = "/babies/qr/{code}";
const api_baby_updateQr = "/babies/image/{code}";
const api_baby_enable = "/babies/enable/{code}";
const api_baby_disable = "/babies/disable/{code}";
const api_baby_update = "/babies/update/{code}";

const api_scale_list = "/scales/list";
const api_scale_search = "/scales/search/{code}";
const api_scale_id_by_hash = "/scales/hash/{hash}";
const api_scale_set = "/scales/set/{hash}";
const api_scale_enable = "/scales/enable/{code}";
const api_scale_disable = "/scales/disable/{code}";
const api_scale_setBaby = "/scales/baby/set";
const api_scale_unsetBaby = "/scales/baby/unset";
const api_scaleData_get = "/scale_data/search/{hash}";
const api_scaleData_getQr = "/scale_data/qr/{hash}";

const api_user_login = "/login";
const api_user_reset = "/reset_password";
const api_user_new = "/users/new";
const api_user_list = "/users/list";

const api_weight_list = "/weight/list";
const api_weight_babies = "/weight/babies/{code}";
const api_weight_scales = "/weight/scales/{code}";
