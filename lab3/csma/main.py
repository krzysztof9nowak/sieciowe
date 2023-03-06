import pygame
from line import *

pygame.init()
surface = pygame.display.set_mode((1600,600))  

line = Line(50)
a = line.add_node(0, "A")
b = line.add_node(45, "B")
c = line.add_node(20, "C")

clock = pygame.time.Clock()
FPS = 60
LINE_UPDATE_PERIOD_MS = 150
LINE_UPDATE_TICK = pygame.USEREVENT + 1 
pygame.time.set_timer(LINE_UPDATE_TICK, LINE_UPDATE_PERIOD_MS)

while True:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            raise SystemExit
        if event.type == LINE_UPDATE_TICK:
            line.tick()
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_a:
                a.send_frame()
            if event.key == pygame.K_b:
                b.send_frame()
            if event.key == pygame.K_c:
                c.send_frame()

    surface.fill((0,0,0))
    line.draw(surface, [10, 50], 1550)
    pygame.display.flip()
    clock.tick(FPS)