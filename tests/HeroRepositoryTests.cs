using System.Collections.Generic;
using Moq;
using Xunit;
using tour_of_heroes_api.Models;

public class HeroRepositoryTests
{
    private readonly Mock<HeroContext> _mockContext;
    private readonly HeroRepository _repository;

    public HeroRepositoryTests()
    {
        _mockContext = new Mock<HeroContext>();
        _repository = new HeroRepository(_mockContext.Object);
    }

    [Fact]
    public void GetAll_ReturnsListOfHeroes()
    {
        // Arrange
        var heroes = new List<Hero>
        {
            new Hero("Superman", "Clark Kent"),
            new Hero("Batman", "Bruce Wayne")
        };
        var mockSet = new Mock<DbSet<Hero>>();
        mockSet.As<IQueryable<Hero>>().Setup(m => m.Provider).Returns(heroes.AsQueryable().Provider);
        mockSet.As<IQueryable<Hero>>().Setup(m => m.Expression).Returns(heroes.AsQueryable().Expression);
        mockSet.As<IQueryable<Hero>>().Setup(m => m.ElementType).Returns(heroes.AsQueryable().ElementType);
        mockSet.As<IQueryable<Hero>>().Setup(m => m.GetEnumerator()).Returns(heroes.GetEnumerator());
        _mockContext.Setup(c => c.Heroes).Returns(mockSet.Object);

        // Act
        var result = _repository.GetAll();

        // Assert
        Assert.Equal(2, result.Count());
    }

    [Fact]
    public void GetById_ReturnsHero()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");
        var mockSet = new Mock<DbSet<Hero>>();
        mockSet.Setup(m => m.Find(1)).Returns(hero);
        _mockContext.Setup(c => c.Heroes).Returns(mockSet.Object);

        // Act
        var result = _repository.GetById(1);

        // Assert
        Assert.Equal("Superman", result.Name);
    }

    [Fact]
    public void Add_AddsHero()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");
        var mockSet = new Mock<DbSet<Hero>>();
        _mockContext.Setup(c => c.Heroes).Returns(mockSet.Object);

        // Act
        _repository.Add(hero);

        // Assert
        mockSet.Verify(m => m.Add(It.IsAny<Hero>()), Times.Once);
        _mockContext.Verify(m => m.SaveChanges(), Times.Once);
    }

    [Fact]
    public void Delete_DeletesHero()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");
        var mockSet = new Mock<DbSet<Hero>>();
        mockSet.Setup(m => m.Find(1)).Returns(hero);
        _mockContext.Setup(c => c.Heroes).Returns(mockSet.Object);

        // Act
        _repository.Delete(1);

        // Assert
        mockSet.Verify(m => m.Remove(It.IsAny<Hero>()), Times.Once);
        _mockContext.Verify(m => m.SaveChanges(), Times.Once);
    }

    [Fact]
    public void Update_UpdatesHero()
    {
        // Arrange
        var hero = new Hero("Superman", "Clark Kent");
        var mockSet = new Mock<DbSet<Hero>>();
        _mockContext.Setup(c => c.Heroes).Returns(mockSet.Object);

        // Act
        _repository.Update(hero);

        // Assert
        mockSet.Verify(m => m.Update(It.IsAny<Hero>()), Times.Once);
        _mockContext.Verify(m => m.SaveChanges(), Times.Once);
    }
}
