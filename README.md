# EE2026_LostInBasys3
Lost in Basys3 is a hide-and-seek game where the player must traverse through the maze and run away from the bot seeker. The player can collect power-ups during the game to enhance or affect their movement speed. Player wins if the timer runs out and loses when they are caught by the seeker.

# Further improvement ideas
- Currently, the BFS of the bot movement will only be reset if every possible move has been exhausted. Resetting the BFS every time the hider moves will be an optimal way of solving this and the late-loop detection issue.
- Portal logic can be implemented for both the seeker and the hider. The BFS logic of the bot shall consider the path length given the possibility of other shortest paths. The two portal nodes will be connected in the overall paths graph.
- Sticky collectibles can be implemented such that the player will consume some of its energy to put the collectible in a selected place for a while. The bot movement will become slower if getting attached to the sticky region.
- **(Hard)** Generate random solvable closed mazes with difficulty levels. DFS logic can be implemented here to break the walls and make a path to connect two diagonal ends of the maze.
- **(Hard)** Currently the bot will only seek and the player will only hide from the bot. Implement the hider bot logic. We can do this by reversing the BFS logic to try to find the longest path and maintaining a danger area to warn the bot to avoid specific nodes near the seeker.  
