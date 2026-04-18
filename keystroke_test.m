import java.awt.Robot;
import java.awt.event.KeyEvent;
robot = Robot();

% Try to type "HELLO"
keys = [KeyEvent.VK_H, KeyEvent.VK_E, KeyEvent.VK_L, KeyEvent.VK_L, KeyEvent.VK_O];
for k = keys
    robot.keyPress(k);
    robot.keyRelease(k);
    pause(0.5); % Small delay between characters
end