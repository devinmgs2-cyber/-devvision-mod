    public override void OnInitializeMelon()
    {
        MelonLogger.Msg("DevVision 0.3.1 - Damage Sync Edition (standalone build)");
        damageEffect = new DamageEffect();
        damageEffect.Initialize();
    }

    public override void OnSceneWasInitialized(int buildIndex, string sceneName)
    {
        damageEffect?.Initialize();
    }

    public override void OnUpdate()
    {
        damageEffect?.Update();
    }

    public override void OnDeinitializeMelon()
    {
        damageEffect?.Cleanup();
    }
}

public class DamageEffect
{
    private Material rgbMaterial;
    private float currentHealth = 100f;
    private float damageIntensity = 0f;
    private float damageFadeDuration = 0.6f;
    private float knockoutFadeDuration = 3f;

    private bool isKnockedOut = false;
    private float knockoutFadeTimer = 0f;

    private List<RGBRenderEffect> activeEffects = new List<RGBRenderEffect>();
    private bool initialized = false;

    public void Initialize()
    {
        if (initialized) return;

        Shader shader = Shader.Find("Hidden/DevVision/RGBShift");
        if (shader == null)
        {
            MelonLogger.Warning("DevVision: RGBShift shader not found. Effect will fall back to copy blit until shader is available.");
            shader = Shader.Find("Hidden/Internal-BlitCopy"); // safe fallback
        }

        if (shader != null)
            rgbMaterial = new Material(shader) { hideFlags = HideFlags.HideAndDontSave };
        else
            MelonLogger.Error("DevVision: No shader available to create material.");

        AttachToAllCameras();
        initialized = true;
        MelonLogger.Msg("DevVision Damage Sync initialized");
    }

    public void Update()
    {
        float newHealth = GetPlayerHealth();

        if (newHealth < currentHealth && newHealth > 0f)
        {
            float damageAmount = currentHealth - newHealth;
            TriggerDamageFlash(damageAmount);
            MelonLogger.Msg($"Hit detected: -{damageAmount:F1}HP");
        }

        currentHealth = newHealth;

        bool playerKnockedOut = newHealth <= 0f;

        if (playerKnockedOut && !isKnockedOut) TriggerKnockout();
        else if (!playerKnockedOut && isKnockedOut) ResetKnockout();

        if (damageIntensity > 0f)
        {
            damageIntensity -= Time.deltaTime / damageFadeDuration;
            damageIntensity = Mathf.Max(0f, damageIntensity);
        }

        if (isKnockedOut)
        {
            knockoutFadeTimer += Time.deltaTime;
            float knockoutIntensity = Mathf.Clamp01(1f - (knockoutFadeTimer / knockoutFadeDuration));
            float finalIntensity = Mathf.Max(damageIntensity, knockoutIntensity);

            if (rgbMaterial != null) rgbMaterial.SetFloat("_Intensity", finalIntensity);

            if (knockoutFadeTimer >= knockoutFadeDuration)
            {
                isKnockedOut = false;
                knockoutFadeTimer = 0f;
            }
        }
        else
        {
            if (rgbMaterial != null) rgbMaterial.SetFloat("_Intensity", damageIntensity);
        }

        if (rgbMaterial != null)
        {
            float dynamicShift = 0.008f * Mathf.Sin(Time.time * 5f);
            rgbMaterial.SetFloat("_Shift", dynamicShift);
        }
    }

    private void TriggerDamageFlash(float damageAmount)
    {
        damageIntensity = Mathf.Min(1f, 0.3f + (damageAmount / 50f));
        if (rgbMaterial != null)
            rgbMaterial.SetFloat("_Shift", 0.02f * Mathf.Clamp01(damageAmount / 30f));
    }

    private void TriggerKnockout()
    {
        isKnockedOut = true;
        knockoutFadeTimer = 0f;
        damageIntensity = 1f;
        if (rgbMaterial != null)
        {
            rgbMaterial.SetFloat("_Shift", 0.015f);
            rgbMaterial.SetFloat("_Intensity", 1f);
        }
        MelonLogger.Msg("Knockout! RGB effect activated");
    }

    private void ResetKnockout()
    {
        damageIntensity = 0f;
        knockoutFadeTimer = 0f;
        MelonLogger.Msg("Recovered!");
    }

    private float GetPlayerHealth()
    {
        try
        {
            Type playerType = Type.GetType("LabFusion.SDK.Players.PlayerVitals, LabFusion");
            if (playerType == null)
            {
                foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
                {
                    try
                    {
                        playerType = asm.GetType("LabFusion.SDK.Players.PlayerVitals");
                    }
                    catch { }
                    if (playerType != null) break;
                }
            }

            if (playerType == null) return currentHealth;

            var players = Resources.FindObjectsOfTypeAll(playerType);
            if (players == null || players.Length == 0) return currentHealth;

            var localPlayer = players.FirstOrDefault();
            if (localPlayer == null) return currentHealth;

            var healthProp = playerType.GetProperty("Health", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (healthProp != null)
            {
                var val = healthProp.GetValue(localPlayer);
                if (val != null) return Convert.ToSingle(val);
            }

            var healthField = playerType.GetField("Health", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (healthField != null)
            {
                var val = healthField.GetValue(localPlayer);
                if (val != null) return Convert.ToSingle(val);
            }

            healthProp = playerType.GetProperty("health", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (healthProp != null)
            {
                var val = healthProp.GetValue(localPlayer);
                if (val != null) return Convert.ToSingle(val);
            }

            healthField = playerType.GetField("health", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (healthField != null)
            {
                var val = healthField.GetValue(localPlayer);
                if (val != null) return Convert.ToSingle(val);
            }
        }
        catch (Exception ex)
        {
            MelonLogger.Warning($"DevVision: GetPlayerHealth reflection failed: {ex}");
        }

        return currentHealth;
    }

    private void AttachToAllCameras()
    {
        Camera[] cameras = UnityEngine.Object.FindObjectsOfType<Camera>(true);

        int attached = 0;
        foreach (Camera cam in cameras)
        {
            if (cam == null) continue;

            var existing = cam.GetComponent<RGBRenderEffect>();
            if (existing != null)
            {
                if (!activeEffects.Contains(existing))
                    activeEffects.Add(existing);
                continue;
            }

            RGBRenderEffect effect = cam.gameObject.AddComponent<RGBRenderEffect>();
            effect.Initialize(rgbMaterial);
            activeEffects.Add(effect);
            attached++;
        }

        MelonLogger.Msg($"Attached to {attached} new camera(s) (total tracked: {activeEffects.Count})");
    }

    public void Cleanup()
    {
        if (rgbMaterial != null)
        {
            UnityEngine.Object.Destroy(rgbMaterial);
            rgbMaterial = null;
        }

        if (activeEffects != null)
        {
            foreach (var effect in activeEffects)
            {
                if (effect != null)
                    UnityEngine.Object.Destroy(effect);
            }
            activeEffects.Clear();
        }

        initialized = false;
    }
}

public class RGBRenderEffect : MonoBehaviour
{
    private Material material;

    public void Initialize(Material mat)
    {
        material = mat;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null || material.shader == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        Graphics.Blit(source, destination, material);
    }
}