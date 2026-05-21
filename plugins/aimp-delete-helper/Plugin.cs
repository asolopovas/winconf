using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using AIMP.SDK;
using AIMP.SDK.MessageDispatcher;
using AIMP.SDK.Playlist.Objects;

namespace WinconfAimpDeleteHelper
{
    [AimpPlugin("winconf_aimp_delete_helper", "asolo", "1.0", AimpPluginType = AimpPluginType.Addons)]
    public class Plugin : AimpPlugin
    {
        private CommandWindow window;

        public override void Initialize()
        {
            window = new CommandWindow(this);
        }

        public override void Dispose()
        {
            if (window != null)
            {
                window.DestroyHandle();
                window = null;
            }
        }

        internal void DeleteCurrent()
        {
            try
            {
                var item = Player.ServicePlayer.CurrentPlaylistItem;
                if (item == null)
                    return;

                var path = item.FileName;
                var playlist = item.PlayList;
                if (string.IsNullOrWhiteSpace(path))
                    return;

                var param = IntPtr.Zero;
                Player.ServiceMessageDispatcher.Send(AimpCoreMessageType.CmdNext, 0, ref param);
                ThreadPool.QueueUserWorkItem(_ => DeleteAfterSkip(playlist, item, path));
            }
            catch (Exception ex)
            {
                Log("delete-current", ex.ToString());
            }
        }

        private void DeleteAfterSkip(IAimpPlaylist playlist, IAimpPlaylistItem item, string path)
        {
            Thread.Sleep(800);
            try
            {
                if (playlist != null && item != null)
                    playlist.Delete(item);
            }
            catch (Exception ex)
            {
                Log("playlist-delete", ex.ToString());
            }

            for (var attempt = 0; attempt < 8; attempt++)
            {
                try
                {
                    if (!File.Exists(path))
                        return;
                    File.Delete(path);
                    return;
                }
                catch (IOException ex)
                {
                    Log("file-delete-retry", attempt + " " + ex.Message);
                    Thread.Sleep(1000);
                }
                catch (UnauthorizedAccessException ex)
                {
                    Log("file-delete-denied", ex.ToString());
                    return;
                }
                catch (Exception ex)
                {
                    Log("file-delete", ex.ToString());
                    return;
                }
            }
        }

        private static void Log(string tag, string message)
        {
            try
            {
                File.AppendAllText(Path.Combine(Path.GetTempPath(), "aimp-delete-plugin.log"), DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " [" + tag + "] " + message + Environment.NewLine);
            }
            catch
            {
            }
        }
    }

    internal class CommandWindow : NativeWindow
    {
        private readonly Plugin plugin;
        private readonly int message;

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int RegisterWindowMessage(string lpString);

        public CommandWindow(Plugin plugin)
        {
            this.plugin = plugin;
            message = RegisterWindowMessage("winconf_aimp_delete_current");
            var cp = new CreateParams();
            cp.Caption = "winconf_aimp_delete_helper";
            cp.ClassName = "winconf_aimp_delete_helper";
            CreateHandle(cp);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == message)
            {
                plugin.DeleteCurrent();
                m.Result = new IntPtr(1);
                return;
            }
            base.WndProc(ref m);
        }
    }
}
