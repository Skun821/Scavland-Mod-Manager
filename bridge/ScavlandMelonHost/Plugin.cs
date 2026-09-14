using System;
using System.Collections;
using System.IO;
using System.Reflection;
using System.Reflection.Emit;
using System.Runtime.InteropServices;
using BepInEx;
using BepInEx.Unity.Mono;

namespace ScavlandMelonHost;

[BepInPlugin("local.scavland.melon-host", "Scavland MelonLoader Host", "0.1.0")]
public sealed class Plugin : BaseUnityPlugin
{
    private const string RuntimeVersion = "0.7.3";
    private static string runtimeDirectory;
    private static string gameRoot;
    private static bool initialized;
    private static object melonUpdateEvent;
    private static MethodInfo melonUpdateInvoke;
    private static object melonLateUpdateEvent;
    private static MethodInfo melonLateUpdateInvoke;
    private static object melonFixedUpdateEvent;
    private static MethodInfo melonFixedUpdateInvoke;
    private static object melonGuiEvent;
    private static MethodInfo melonGuiInvoke;
    private static object melonQuitEvent;
    private static MethodInfo melonQuitInvoke;
    private static object melonDefiniteQuitEvent;
    private static MethodInfo melonDefiniteQuitInvoke;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibrary(string fileName);

    private void Awake()
    {
        if (initialized) return;
        initialized = true;
        gameRoot = Paths.GameRootPath;
        runtimeDirectory = Path.Combine(gameRoot, "MelonLoader", "net472");
        AppDomain.CurrentDomain.AssemblyResolve += ResolveMelonAssembly;

        try
        {
            string loaderPath = Path.Combine(runtimeDirectory, "MelonLoader.dll");
            if (!File.Exists(loaderPath))
            {
                Logger.LogWarning("MelonLoader runtime was not found. Install the Scavland Melon Host runtime package to enable Melon mods.");
                return;
            }

            Assembly loader = Assembly.LoadFrom(loaderPath);
            InstallBootstrapAdapter(loader);
            Type core = loader.GetType("MelonLoader.Core", true);
            MethodInfo initialize = core.GetMethod("InitializeScavlandCompatibility", BindingFlags.NonPublic | BindingFlags.Static);
            MethodInfo start = core.GetMethod("StartScavlandCompatibility", BindingFlags.NonPublic | BindingFlags.Static);
            if (initialize == null || start == null)
                throw new InvalidOperationException("Scavland MelonLoader compatibility entry points were not found.");

            object initializeResult = initialize.Invoke(null, null);
            if (initializeResult is int status && status != 0)
                throw new InvalidOperationException("MelonLoader initialization returned status " + status + ".");

            object startResult = start.Invoke(null, null);
            if (startResult is bool started && !started)
                throw new InvalidOperationException("MelonLoader did not finish startup.");

            BindMelonEvents(loader);
            LogRegisteredMelons(loader);
            Logger.LogInfo("MelonLoader " + RuntimeVersion + " compatibility host started. Loading folders: Mods, Plugins, UserLibs.");
        }
        catch (Exception e)
        {
            Logger.LogError("MelonLoader host failed to start: " + Unwrap(e));
        }
    }

    private static Assembly ResolveMelonAssembly(object sender, ResolveEventArgs args)
    {
        AssemblyName request = new AssemblyName(args.Name);
        if (string.IsNullOrEmpty(request.Name) || string.IsNullOrEmpty(runtimeDirectory)) return null;
        string path = Path.Combine(runtimeDirectory, request.Name + ".dll");
        try { return File.Exists(path) ? Assembly.LoadFrom(path) : null; }
        catch { return null; }
    }

    private void LogRegisteredMelons(Assembly loader)
    {
        Type melonBase = loader.GetType("MelonLoader.MelonBase", true);
        IEnumerable registered = melonBase.GetProperty("RegisteredMelons", BindingFlags.Static | BindingFlags.Public)
            .GetValue(null, null) as IEnumerable;
        int count = 0;
        if (registered != null)
        {
            foreach (object melon in registered)
            {
                object info = melon.GetType().GetProperty("Info").GetValue(melon, null);
                string name = info == null ? melon.GetType().FullName : (string)info.GetType().GetProperty("Name").GetValue(info, null);
                Logger.LogInfo("Loaded Melon MOD: " + name);
                count++;
            }
        }
        Logger.LogInfo("Melon compatibility load completed: " + count + " MOD(s)/plugin(s).");
    }

    private static void BindMelonEvents(Assembly loader)
    {
        Type events = loader.GetType("MelonLoader.MelonEvents", true);
        BindMelonEvent(events, "OnUpdate", out melonUpdateEvent, out melonUpdateInvoke);
        BindMelonEvent(events, "OnLateUpdate", out melonLateUpdateEvent, out melonLateUpdateInvoke);
        BindMelonEvent(events, "OnFixedUpdate", out melonFixedUpdateEvent, out melonFixedUpdateInvoke);
        BindMelonEvent(events, "OnGUI", out melonGuiEvent, out melonGuiInvoke);
        BindMelonEvent(events, "OnApplicationQuit", out melonQuitEvent, out melonQuitInvoke);
        BindMelonEvent(events, "OnApplicationDefiniteQuit", out melonDefiniteQuitEvent, out melonDefiniteQuitInvoke);
    }

    private static void BindMelonEvent(Type events, string name, out object eventObject, out MethodInfo invoke)
    {
        eventObject = events.GetField(name, BindingFlags.Static | BindingFlags.Public).GetValue(null);
        invoke = eventObject.GetType().GetMethod("Invoke", BindingFlags.Instance | BindingFlags.Public);
    }

    private void InvokeMelonEvent(object eventObject, MethodInfo invoke)
    {
        if (eventObject == null || invoke == null) return;
        try { invoke.Invoke(eventObject, null); }
        catch (Exception e) { Logger.LogError("Melon lifecycle dispatch failed: " + Unwrap(e)); }
    }

    private void Update() => InvokeMelonEvent(melonUpdateEvent, melonUpdateInvoke);
    private void LateUpdate() => InvokeMelonEvent(melonLateUpdateEvent, melonLateUpdateInvoke);
    private void FixedUpdate() => InvokeMelonEvent(melonFixedUpdateEvent, melonFixedUpdateInvoke);
    private void OnGUI() => InvokeMelonEvent(melonGuiEvent, melonGuiInvoke);
    private void OnApplicationQuit()
    {
        InvokeMelonEvent(melonQuitEvent, melonQuitInvoke);
        InvokeMelonEvent(melonDefiniteQuitEvent, melonDefiniteQuitInvoke);
    }

    private void InstallBootstrapAdapter(Assembly loader)
    {
        Type interopType = loader.GetType("MelonLoader.InternalUtils.BootstrapInterop", true);
        Type libraryType = loader.GetType("MelonLoader.InternalUtils.BootstrapLibrary", true);
        object library = Activator.CreateInstance(libraryType, true);
        SetDelegate(libraryType, library, "GetLoaderConfig", BuildConfigDelegate);
        SetDelegate(libraryType, library, "MonoGetRuntimeHandle", BuildMonoHandleDelegate);
        SetDelegate(libraryType, library, "IsConsoleOpen", BuildFalseDelegate);
        SetDelegate(libraryType, library, "NativeHookAttach", BuildNoOpDelegate);
        SetDelegate(libraryType, library, "NativeHookDetach", BuildNoOpDelegate);
        SetDelegate(libraryType, library, "LogMsg", BuildNoOpDelegate);
        SetDelegate(libraryType, library, "LogError", BuildNoOpDelegate);
        SetDelegate(libraryType, library, "LogMelonInfo", BuildNoOpDelegate);
        SetDelegate(libraryType, library, "MonoInstallHooks", BuildNoOpDelegate);
        SetDelegate(libraryType, library, "MonoGetDomainPtr", BuildZeroPointerDelegate);
        interopType.GetProperty("Library", BindingFlags.Static | BindingFlags.NonPublic)
            .SetValue(null, library, null);
    }

    private static void SetDelegate(Type libraryType, object library, string name, Func<Type, Delegate> factory)
    {
        PropertyInfo property = libraryType.GetProperty(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
        // Scavland's stripped mscorlib does not provide MissingMemberException(string, string).
        // Keep diagnostics in a constructor guaranteed by the game's runtime instead.
        if (property == null) throw new InvalidOperationException("MelonLoader bootstrap property was not found: " + libraryType.FullName + "." + name);
        property.SetValue(library, factory(property.PropertyType), null);
    }

    private static Delegate BuildNoOpDelegate(Type delegateType)
    {
        return BuildDynamicDelegate(delegateType, il => il.Emit(OpCodes.Ret));
    }

    private static Delegate BuildFalseDelegate(Type delegateType)
    {
        return BuildDynamicDelegate(delegateType, il => { il.Emit(OpCodes.Ldc_I4_0); il.Emit(OpCodes.Ret); });
    }

    private static Delegate BuildZeroPointerDelegate(Type delegateType)
    {
        return BuildDynamicDelegate(delegateType, il => { il.Emit(OpCodes.Ldc_I4_0); il.Emit(OpCodes.Conv_I); il.Emit(OpCodes.Ret); });
    }

    private static Delegate BuildMonoHandleDelegate(Type delegateType)
    {
        return BuildDynamicDelegate(delegateType, il =>
        {
            il.Emit(OpCodes.Call, typeof(Plugin).GetMethod(nameof(GetMonoRuntimeHandle), BindingFlags.Static | BindingFlags.NonPublic));
            il.Emit(OpCodes.Ret);
        });
    }

    private static Delegate BuildConfigDelegate(Type delegateType)
    {
        return BuildDynamicDelegate(delegateType, il =>
        {
            il.Emit(OpCodes.Ldarg_0);
            il.Emit(OpCodes.Ldind_Ref);
            il.Emit(OpCodes.Call, typeof(Plugin).GetMethod(nameof(ConfigureLoader), BindingFlags.Static | BindingFlags.NonPublic));
            il.Emit(OpCodes.Ret);
        });
    }

    private static Delegate BuildDynamicDelegate(Type delegateType, Action<ILGenerator> emit)
    {
        MethodInfo invoke = delegateType.GetMethod("Invoke");
        ParameterInfo[] parameters = invoke.GetParameters();
        Type[] parameterTypes = new Type[parameters.Length];
        for (int i = 0; i < parameters.Length; i++) parameterTypes[i] = parameters[i].ParameterType;
        // Scavland's mscorlib omits the Module-based DynamicMethod overload.
        // The owner-free overload still permits the internal MelonLoader delegates.
        DynamicMethod method = new DynamicMethod("ScavlandMelonHost_" + delegateType.Name, invoke.ReturnType, parameterTypes, true);
        emit(method.GetILGenerator());
        return method.CreateDelegate(delegateType);
    }

    private static void ConfigureLoader(object config)
    {
        object loaderConfig = config.GetType().GetProperty("Loader").GetValue(config, null);
        loaderConfig.GetType().GetProperty("BaseDirectory", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
            .SetValue(loaderConfig, gameRoot, null);
        loaderConfig.GetType().GetProperty("DisableStartScreen", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
            .SetValue(loaderConfig, true, null);
    }

    private static IntPtr GetMonoRuntimeHandle()
    {
        string dataDirectory = Path.Combine(gameRoot, "Scavland_Data");
        string[] candidates = Directory.Exists(dataDirectory)
            ? Directory.GetFiles(dataDirectory, "mono-2.0-bdwgc.dll", SearchOption.AllDirectories)
            : Array.Empty<string>();
        if (candidates.Length == 0) return IntPtr.Zero;
        return LoadLibrary(candidates[0]);
    }

    private static string Unwrap(Exception exception)
    {
        while (exception is TargetInvocationException && exception.InnerException != null)
            exception = exception.InnerException;
        return exception.ToString();
    }
}
