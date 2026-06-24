/**
 * EntryAbility - 应用主入口 Ability
 * 职责：应用启动时初始化轻量级数据存储、用药提醒服务，并加载闪屏页面作为首个UI界面
 * 生命周期：onCreate → onWindowStageCreate → onForeground → onBackground → onWindowStageDestroy → onDestroy
 */
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ReminderService } from '../common/service/ReminderService';
import { HealthViewModel } from '../viewmodel/HealthViewModel';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';

const DOMAIN = 0x0000; // hilog 日志域标识，0x0000 表示默认域
const TAG = 'EntryAbility'; // 日志标签，用于过滤本 Ability 的日志

export default class EntryAbility extends UIAbility {
  /**
   * Ability 创建时的回调，在应用首次启动时执行
   * 主要完成：设置颜色模式 → 初始化 Preferences 存储 → 初始化用药提醒服务
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      // 设置颜色模式为跟随系统，不强制指定深色/浅色
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
    // 初始化轻量级键值对存储，必须在其他模块使用前完成
    PreferencesUtil.getInstance().init(this.context);
    // 初始化后台提醒服务（通知权限申请 + 通知渠道创建 + 示例提醒同步）
    this.initReminderService();
  }

  /**
   * 初始化用药提醒服务的完整流程：
   * 1. 获取 ReminderService 单例并初始化（申请通知权限、创建通知渠道）
   * 2. 初始化示例用药提醒数据
   * 3. 将所有启用的提醒同步到系统后台提醒代理
   */
  private async initReminderService(): Promise<void> {
    try {
      const reminderService: ReminderService = ReminderService.getInstance();
      await reminderService.init(this.context);
      const healthViewModel: HealthViewModel = new HealthViewModel();
      healthViewModel.initSampleReminders();
      await healthViewModel.syncAllReminders();
      hilog.info(DOMAIN, TAG, 'ReminderService initialized and reminders synced');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to init ReminderService: %{public}s', JSON.stringify(err));
    }
  }

  /** Ability 销毁回调，可在此释放全局资源 */
  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  /**
   * 窗口阶段创建回调，在此加载应用的第一个页面
   * 使用 SplashPage（闪屏页）作为入口，闪屏页会根据首次启动/登录状态自动跳转
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  /** 窗口阶段销毁回调 */
  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  /** Ability 切回前台回调 */
  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  /** Ability 切到后台回调 */
  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
