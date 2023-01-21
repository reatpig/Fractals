#include <SFML/Graphics.hpp>
#include "CImg.h"
#include "Calculations.cuh"

using namespace cimg_library;
void calcColorPerIter(uint8_t* whitchColorPerIter, CImg < unsigned char>& img);

int main()
{
	sf::RenderWindow window(sf::VideoMode(WIDTH, HEIGHT), "Fractal");
	window.setFramerateLimit(30);

	//y-axis
	sf::VertexArray ordinate(sf::LinesStrip, 2);
	ordinate[0].position = sf::Vector2f(0, HEIGHT / 2);
	ordinate[0].color = sf::Color::Black;
	ordinate[1].position = sf::Vector2f(WIDTH, HEIGHT / 2);
	ordinate[1].color = sf::Color::Black;

	//x-axis
	sf::VertexArray abscissa(sf::LinesStrip, 2);
	abscissa[0].position = sf::Vector2f(WIDTH / 2, 0);
	abscissa[0].color = sf::Color::Black;
	abscissa[1].position = sf::Vector2f(WIDTH / 2, HEIGHT);
	abscissa[1].color = sf::Color::Black;

	//Text 
	sf::Font font;
	font.loadFromFile("ARIALN.TTF");
	sf::Text text;
	text.setFont(font);
	text.setFillColor(sf::Color::Black);
	text.setOutlineColor(sf::Color::White);
	text.setOutlineThickness(1);
	text.setCharacterSize(20);

	bool pressedLMB = false;
	double startx{ 0 };
	double deltaCoorx{ 0 };
	double starty{ 0 };
	double deltaCoory{ 0 };
	bool pause = false;
	double leftTopx{ 0 }, leftTopy{ 0 };
	double numberPerPixel = 0.003;

	sf::Texture texture;
	sf::Sprite sprite;
	texture.create(WIDTH, HEIGHT);

	std::vector<sf::Uint8> pixelBuffer(WIDTH * HEIGHT * 4);
	std::vector<sf::Uint8> colorPerIter(1549 * 4);
	CImg < unsigned char>  img("Gradient.bmp");
	calcColorPerIter(colorPerIter.data(), img);
	defineColorPerIter(colorPerIter.data());
	colorPerIter.clear();
	img.clear();

	sf::Clock clock;

	while (window.isOpen())
	{
		sf::Event event;
		while (window.pollEvent(event))
		{
			if (event.type == sf::Event::Closed)
				window.close();

			//Zoom in and out
			else if (event.type == sf::Event::MouseWheelMoved)
			{
				sf::Vector2f mousePos = window.mapPixelToCoords(sf::Mouse::getPosition(window));
				double  mousePosx(mousePos.x);
				double  mousePosy(mousePos.y);

				double numberPerPixelOld = numberPerPixel;
				numberPerPixel += (event.mouseWheel.delta / 10.) * numberPerPixel;

				double deltaPixel = numberPerPixelOld - numberPerPixel;
				if (numberPerPixel < 0)
					numberPerPixel = 0.000000001;

				//Keep mouse coordinates immutable
				leftTopx = (-mousePosx * deltaPixel + deltaPixel * WIDTH / 2 + leftTopx * numberPerPixelOld) / (numberPerPixel);
				leftTopy = (-mousePosy * deltaPixel + deltaPixel * HEIGHT / 2 + leftTopy * numberPerPixelOld) / numberPerPixel;
				text.setString(std::to_string((mousePos.x - WIDTH / 2 - leftTopx) * numberPerPixel) + ' '
					+ std::to_string((-mousePos.y + HEIGHT / 2 + leftTopy) * numberPerPixel) + '\n' + std::to_string(numberPerPixel));
			}
			// Coordinates show and move camera 
			else if (event.type == sf::Event::MouseMoved)
			{
				sf::Vector2f mousePos = window.mapPixelToCoords(sf::Mouse::getPosition(window));
				double  mousePosx(mousePos.x);
				double  mousePosy(mousePos.y);

				if (pressedLMB) {
					leftTopx = (mousePosx - startx) + deltaCoorx;
					leftTopy = (mousePosy - starty) + deltaCoory;
				}
				text.setString(std::to_string((mousePos.x - WIDTH / 2 - leftTopx) * numberPerPixel) + ' '
					+ std::to_string((-mousePos.y + HEIGHT / 2 + leftTopy) * numberPerPixel) + '\n' + std::to_string(numberPerPixel));
				text.setPosition(mousePos + sf::Vector2f(0, -20));
			}
			//Move camera when LMB pressed
			else if (event.type == sf::Event::MouseButtonPressed)
			{
				if (sf::Mouse::isButtonPressed(sf::Mouse::Left)) {
					sf::Vector2f mousePos = window.mapPixelToCoords(sf::Mouse::getPosition(window));
					pressedLMB = true;
					startx = mousePos.x;
					starty = mousePos.y;

					deltaCoorx = leftTopx;
					deltaCoory = leftTopy;
				}
			}
			else  if (event.type == sf::Event::MouseButtonReleased)
			{
				pressedLMB = false;
			}
			else if (event.type == sf::Event::KeyPressed) 
			{
				if (event.key.code == sf::Keyboard::Space)
					pause = !pause;
			}

			ordinate[0].position = sf::Vector2f(0, HEIGHT / 2 + leftTopy);
			ordinate[1].position = sf::Vector2f(WIDTH, HEIGHT / 2 + leftTopy);

			abscissa[0].position = sf::Vector2f(WIDTH / 2 + leftTopx, 0);
			abscissa[1].position = sf::Vector2f(WIDTH / 2 + leftTopx, HEIGHT);
		}
		//Rendering
		window.clear(sf::Color::Cyan);
		if (pause) clock.restart();
		render(numberPerPixel, leftTopx, leftTopy, pixelBuffer.data(), clock.restart().asMicroseconds());
		texture.update(pixelBuffer.data());
		sprite.setTexture(texture);
		window.draw(sprite);
		window.draw(ordinate);
		window.draw(abscissa);
		window.draw(text);
		window.display();
	}
	return 0;
}

void calcColorPerIter(uint8_t* whitchColorPerIter, CImg < unsigned char>& img) {
	for (int i = 0; i <= iterations; ++i) {
		int colorI = (int)(sqrt((double)i / iterations * 1024 + 10) * 45) % img.width();
		for (int r = 0; r < 3; ++r)
			whitchColorPerIter[4 * i + r] = img(colorI, 0, 0, r);
		whitchColorPerIter[4 * i + 3] = 255;
	}
}


