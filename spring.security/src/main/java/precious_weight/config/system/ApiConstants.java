package precious_weight.config.system;

public class ApiConstants {
    public static final String Controller_List = "/list";
    public static final String Controller_New = "/new";
    public static final String Controller_Save = "/save";
    public static final String Controller_Search = "/search/{id}";
    public static final String Controller_Image = "/image/{id}";
    public static final String Controller_Enable= "/enable/{id}";
    public static final String Controller_Disable = "/disable/{id}";
    public static final String Controller_Update = "/update/{id}";

    // App -------------------------------------------------
    public static final String BabyController = "/babies";

    public static final String ScaleController = "/scales";
    public static final String ScaleController_SetScaleToUser = "/set";
    public static final String ScaleController_SetBaby = "/baby/set";
    public static final String ScaleController_UnsetBaby = "/baby/unset";

    public static final String WeightController = "/weight";
    public static final String WeightController_Babies = "/babies/{babyId}";
    public static final String WeightController_Scales = "/scales/{scaleId}";

    public static final String AuditController = "/audit";
    public static final String AuditController_Weights = "/weights/{babyId}";
    public static final String AuditController_Scales = "/scales/{scaleId}";
    public static final String AuditController_Babies = "/babies/{babyId}";

    // Auth -------------------------------------------------
    public static final String LoginController = "/login";
    public static final String LoginController_ResetPass = "/reset_password";
    public static final String LoginController_Scope = "scope";
    public static final String LoginController_BackEndName = "precious_weight_backend";

    public static final String UserController = "/users";
    public static final String ScaleDataController = "/scale_data";
}
