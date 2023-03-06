from matplotlib.pyplot import draw
import pygame
import random
class Node:
    def __init__(self, line, element: int, name):
        self.line = line
        self.element = element
        self.state = 'RX'
        self.counter = 0
        self.fails_count = 0
        self.wait_ticks = 0
        self.name = name

    def tick(self):
        if self.state == 'WaitCollision':
            if self.wait_ticks <= 0:
                self.state = 'WaitTX'
            else:
                self.wait_ticks -= 1



        if self.state == 'WaitTX' and self.element.is_free():
            self.start_transmition()

        if self.state == "TX":
            if self.element.has_collision():
                self.collision()

            self.counter += 1
            if self.counter == self.line.get_frame_size():
                self.stop_transmision()
                print(f"Node {self.name} TX completed")

    def start_transmition(self):
        print(f"Node {self.name} - TX started")
        self.state = 'TX'
        self.counter = 0
        self.line.add_fronts(self.element.id, True, self.name)

    def stop_transmision(self):
        self.state = 'RX'
        self.line.add_fronts(self.element.id, False, self.name)

    def send_frame(self):
        if self.state == 'RX':
            self.fails_count = 0
            self.state = 'WaitTX'

    def collision(self):
        assert(self.state == 'TX')

        print(f"Node {self.name} - detected collision #{self.fails_count}")
        self.stop_transmision()
        self.fails_count += 1
        max_wait_slots = 2**self.fails_count - 1
        wait_slots = random.randint(0, max_wait_slots)
        print(f"Node {self.name} - wait {wait_slots} / {max_wait_slots} slots")
        self.wait_ticks = wait_slots * self.line.get_frame_size()

        self.state = 'WaitCollision' 


    def get_status(self):
        text = f"Node {self.name}\n"
        text += self.state + '\n'

        if self.state == 'TX':
            text += f'{self.counter} / {self.line.get_frame_size()} bits'

        if self.state == 'WaitCollision':
            text += f'ticks: {self.wait_ticks}'

        return text


class Elements:
    def __init__(self, id: int):
        self.id = id
        self.state = set()
        self.has_node = False

    def is_free(self):
        return not self.state

    def has_collision(self):
        return len(self.state) > 1

class Front:
    def __init__(self, line, pos, dir, name, activate):
        self.line = line
        self.pos = pos
        self.dir = dir
        self.name = name
        self.activate = activate

    def tick(self):
        element = self.line.elements[self.pos].state
        if self.activate:
            element.add(self.name)
        else:
            if self.name in element:
                element.remove(self.name)

        self.pos += self.dir
        
        if self.pos == -1 or self.pos == len(self.line.elements):
            self.line.fronts.remove(self)
        
        

class Line:
    def __init__(self, n: int):
        self.elements = [Elements(i) for i in range(n)]
        self.fronts = []
        self.nodes = []

    def tick(self):
        for front in self.fronts:
            front.tick()

        for node in self.nodes:
            node.tick()

    def add_node(self, pos, name):
        element = self.elements[pos]
        element.has_node = True
        node = Node(self, element, name)
        self.nodes.append(node)
        return node

    def add_fronts(self, pos, phase, name):
        left = Front(self, pos, -1, name, phase)
        right = Front(self, pos, 1, name, phase)
        self.fronts.append(left)
        self.fronts.append(right)

    def get_frame_size(self):
        return 2 * len(self.elements)

    def draw(self, surface, pos, size):
        color = (255, 255, 255)

        step = int(size / len(self.elements))
        rect_size = int(0.9 * step) 

        big_font = pygame.font.Font(pygame.font.get_default_font(), rect_size)
        small_font = pygame.font.Font(pygame.font.get_default_font(), rect_size // 2)


        for i, element in enumerate(self.elements):
            text = ''.join(element.state)
            rect_pos = (pos[0] + i*step, pos[1])
            rect = pygame.Rect(rect_pos, (rect_size, rect_size))
            if element.has_node:
                pygame.draw.rect(surface, color, rect,  3)
            else:
                pygame.draw.rect(surface, color, rect,  1)
            surface.blit(small_font.render(text, True, color), rect_pos)


        for node in self.nodes:
            x = pos[0] + node.element.id*step
            y = pos[1] + 30
            lines = node.get_status().splitlines()
            for i, l in enumerate(lines):
                surface.blit(big_font.render(l, True, color), (x, y + rect_size*i))

