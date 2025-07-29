
const lbl_home_br = 'Home';
const lbl_babies_br = 'Bebês';
const lbl_scales_br = 'Balanças';
const lbl_logs_br = 'Registros';
const lbl_connect_scale_to_network_br = 'Conectar Balança ao WiFi';
const lbl_wifi_data_br ='Dados do WiFi';
const lbl_wifi_login_br = 'Nome da Rede Wifi: ';
const lbl_wifi_pass_br = 'Senha do WiFi: ';
const lbl_wifi_btn_connect_br = 'Conectar';

const lbl_home = 'Home';
const lbl_babies = 'Babies';
const lbl_scales = 'Scales';
const lbl_logs = 'Registers';
const lbl_connect_scale_to_network = 'Connect Scale to WiFi';

const  address_localhost = 'http://localhost:8080';
const  address_api = 'http://192.168.0.15:8080'; //No android, localhost é 10.0.2.2, e não 'localhost' ou '127.0.0.1'

const api_pattern_code = "{code}";
const api_pattern_hash = "{hash}";

const api_audit_babies = '/audit/babies/{code}';
const api_audit_scales = '/audit/scales/{code}';
const api_audit_weights = '/audit/weights/{code}';

const api_baby_list = '/babies/list';
const api_baby_search = '/babies/search/{code}';
const api_baby_new= '/babies/save';
const api_baby_updateQr = '/babies/image/{code}';
const api_baby_enable = '/babies/enable/{code}';
const api_baby_disable = '/babies/disable/{code}';
const api_baby_update = '/babies/update/{code}';

const api_scale_list = '/scales/list';
const api_scale_search = '/scales/search/{code}';
const api_scale_new= '/scales/save/{hash}';
const api_scale_update = '/scales/update/{code}';
const api_scale_enable = '/scales/enable/{code}';
const api_scale_disable = '/scales/disable/{code}';
const api_scale_set = '/scales/baby/set';
const api_scale_unset = '/scales/baby/unset';

const api_user_login = '/login';
const api_user_new = '/users/new';
const api_user_list = '/users/list';

const api_weight_list = '/weight/list';
const api_weight_babies = '/weight/babies/{code}';
const api_weight_scales = '/weight/scales/{code}';



